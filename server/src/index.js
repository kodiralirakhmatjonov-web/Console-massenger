import { DurableObject } from 'cloudflare:workers';

const MAX_FRAME_BYTES = 64 * 1024;
const MAX_HISTORY_LIMIT = 100;

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store',
    },
  });
}

function isWebSocketUpgrade(request) {
  return request.headers.get('Upgrade')?.toLowerCase() === 'websocket';
}

function parseTerminalRoute(pathname) {
  const match = pathname.match(/^\/v1\/terminal\/([A-Za-z0-9_-]{1,96})\/(socket|history)$/);
  if (!match) return null;
  return { terminalId: match[1], action: match[2] };
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === 'GET' && url.pathname === '/health') {
      return json({
        ok: true,
        service: 'console-network',
        protocol: '0.1',
        transport: 'cloudflare-durable-objects',
      });
    }

    const route = parseTerminalRoute(url.pathname);
    if (!route) {
      return json(
        {
          error: 'NOT_FOUND',
          message: 'Supported endpoints: /health, /v1/terminal/:id/socket, /v1/terminal/:id/history',
        },
        404,
      );
    }

    const room = env.TERMINALS.getByName(route.terminalId);

    if (route.action === 'socket') {
      if (request.method !== 'GET' || !isWebSocketUpgrade(request)) {
        return json({ error: 'WEBSOCKET_UPGRADE_REQUIRED' }, 426);
      }

      const nodeId = url.searchParams.get('node');
      if (!nodeId || !/^[A-Za-z0-9_-]{3,96}$/.test(nodeId)) {
        return json({ error: 'INVALID_NODE_ID' }, 400);
      }

      return room.fetch(request);
    }

    if (route.action === 'history') {
      if (request.method !== 'GET') {
        return json({ error: 'METHOD_NOT_ALLOWED' }, 405);
      }
      return room.fetch(request);
    }

    return json({ error: 'NOT_FOUND' }, 404);
  },
};

export class TerminalRoom extends DurableObject {
  constructor(ctx, env) {
    super(ctx, env);
    this.ctx = ctx;
    this.env = env;
    this.sql = ctx.storage.sql;

    this.sql.exec(`
      CREATE TABLE IF NOT EXISTS frames (
        id TEXT PRIMARY KEY,
        sender TEXT NOT NULL,
        ciphertext TEXT NOT NULL,
        sent_at INTEGER NOT NULL,
        received_at INTEGER NOT NULL
      );
      CREATE INDEX IF NOT EXISTS idx_frames_sent_at
        ON frames(sent_at DESC);
    `);

    this.ctx.setWebSocketAutoResponse(
      new WebSocketRequestResponsePair('ping', 'pong'),
    );
  }

  async fetch(request) {
    const url = new URL(request.url);

    if (url.pathname.endsWith('/history')) {
      return this.#history(url);
    }

    if (!isWebSocketUpgrade(request)) {
      return json({ error: 'WEBSOCKET_UPGRADE_REQUIRED' }, 426);
    }

    const nodeId = url.searchParams.get('node');
    if (!nodeId || !/^[A-Za-z0-9_-]{3,96}$/.test(nodeId)) {
      return json({ error: 'INVALID_NODE_ID' }, 400);
    }

    const pair = new WebSocketPair();
    const [client, server] = Object.values(pair);

    this.ctx.acceptWebSocket(server);

    const attachment = {
      nodeId,
      sessionId: crypto.randomUUID(),
      joinedAt: Date.now(),
    };
    server.serializeAttachment(attachment);

    server.send(
      JSON.stringify({
        type: 'hello',
        sessionId: attachment.sessionId,
        serverTime: Date.now(),
      }),
    );

    return new Response(null, {
      status: 101,
      webSocket: client,
    });
  }

  async webSocketMessage(ws, message) {
    if (typeof message !== 'string') {
      ws.send(JSON.stringify({ type: 'error', code: 'TEXT_FRAME_REQUIRED' }));
      return;
    }

    if (new TextEncoder().encode(message).byteLength > MAX_FRAME_BYTES) {
      ws.send(JSON.stringify({ type: 'error', code: 'FRAME_TOO_LARGE' }));
      return;
    }

    let frame;
    try {
      frame = JSON.parse(message);
    } catch {
      ws.send(JSON.stringify({ type: 'error', code: 'INVALID_JSON' }));
      return;
    }

    if (frame?.type !== 'frame') {
      ws.send(JSON.stringify({ type: 'error', code: 'UNSUPPORTED_FRAME_TYPE' }));
      return;
    }

    if (
      typeof frame.id !== 'string' ||
      frame.id.length < 8 ||
      frame.id.length > 128 ||
      typeof frame.ciphertext !== 'string' ||
      frame.ciphertext.length === 0 ||
      frame.ciphertext.length > MAX_FRAME_BYTES ||
      !Number.isSafeInteger(frame.sentAt)
    ) {
      ws.send(JSON.stringify({ type: 'error', code: 'INVALID_FRAME' }));
      return;
    }

    const attachment = ws.deserializeAttachment();
    const sender = attachment?.nodeId;
    if (!sender) {
      ws.send(JSON.stringify({ type: 'error', code: 'SESSION_STATE_MISSING' }));
      return;
    }

    const receivedAt = Date.now();

    this.sql.exec(
      `INSERT OR IGNORE INTO frames (id, sender, ciphertext, sent_at, received_at)
       VALUES (?, ?, ?, ?, ?)`,
      frame.id,
      sender,
      frame.ciphertext,
      frame.sentAt,
      receivedAt,
    );

    ws.send(
      JSON.stringify({
        type: 'ack',
        id: frame.id,
        state: 'persisted',
        receivedAt,
      }),
    );

    const outbound = JSON.stringify({
      type: 'frame',
      id: frame.id,
      sender,
      ciphertext: frame.ciphertext,
      sentAt: frame.sentAt,
      receivedAt,
    });

    for (const peer of this.ctx.getWebSockets()) {
      if (peer === ws || peer.readyState !== WebSocket.OPEN) continue;
      peer.send(outbound);
    }
  }

  async webSocketClose(ws, code, reason) {
    ws.close(code, reason);
  }

  #history(url) {
    const requestedLimit = Number.parseInt(url.searchParams.get('limit') ?? '50', 10);
    const limit = Number.isFinite(requestedLimit)
      ? Math.min(Math.max(requestedLimit, 1), MAX_HISTORY_LIMIT)
      : 50;

    const beforeRaw = Number.parseInt(url.searchParams.get('before') ?? `${Date.now() + 1}`, 10);
    const before = Number.isSafeInteger(beforeRaw) ? beforeRaw : Date.now() + 1;

    const rows = [
      ...this.sql.exec(
        `SELECT id, sender, ciphertext, sent_at AS sentAt, received_at AS receivedAt
         FROM frames
         WHERE sent_at < ?
         ORDER BY sent_at DESC
         LIMIT ?`,
        before,
        limit,
      ),
    ];

    return json({
      frames: rows.reverse(),
      nextBefore: rows.length === limit ? rows[0]?.sentAt ?? null : null,
    });
  }
}
