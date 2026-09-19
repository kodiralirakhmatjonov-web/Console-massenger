const MAX_FRAME_BYTES = 64 * 1024;
const HISTORY_LIMIT = 100;

function json(data, status = 200, extraHeaders = {}) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
      ...extraHeaders,
    },
  });
}

function safeId(value, maxLength = 96) {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  if (!trimmed || trimmed.length > maxLength) return null;
  if (!/^[A-Za-z0-9._:-]+$/.test(trimmed)) return null;
  return trimmed;
}

function nowISO() {
  return new Date().toISOString();
}

function randomEventId() {
  return crypto.randomUUID();
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === "GET" && url.pathname === "/health") {
      return json({
        service: "console-realtime",
        status: "READY",
        protocol: 1,
        time: nowISO(),
      });
    }

    const terminalMatch = url.pathname.match(/^\/v1\/terminals\/([^/]+)\/(socket|history)$/);
    if (!terminalMatch) {
      return json(
        {
          error: "ROUTE_NOT_FOUND",
          message: "Console realtime endpoint not found.",
        },
        404,
      );
    }

    const terminalId = safeId(decodeURIComponent(terminalMatch[1]));
    if (!terminalId) {
      return json({ error: "INVALID_TERMINAL_ID" }, 400);
    }

    const roomId = env.TERMINALS.idFromName(terminalId);
    const room = env.TERMINALS.get(roomId);

    const forwarded = new Request(request);
    forwarded.headers.set("x-console-terminal-id", terminalId);
    return room.fetch(forwarded);
  },
};

export class TerminalRoom {
  constructor(ctx, env) {
    this.ctx = ctx;
    this.env = env;

    this.ctx.blockConcurrencyWhile(async () => {
      this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS messages (
          seq INTEGER PRIMARY KEY AUTOINCREMENT,
          event_id TEXT NOT NULL UNIQUE,
          client_id TEXT NOT NULL,
          sender_node TEXT NOT NULL,
          ciphertext TEXT NOT NULL,
          created_at TEXT NOT NULL
        );
      `);

      this.ctx.storage.sql.exec(`
        CREATE INDEX IF NOT EXISTS idx_messages_seq
        ON messages(seq DESC);
      `);
    });
  }

  async fetch(request) {
    const url = new URL(request.url);
    const terminalId = request.headers.get("x-console-terminal-id") || "unknown";

    if (url.pathname.endsWith("/history") && request.method === "GET") {
      const limitRaw = Number(url.searchParams.get("limit") || 50);
      const limit = Math.max(1, Math.min(HISTORY_LIMIT, Number.isFinite(limitRaw) ? limitRaw : 50));

      const rows = [
        ...this.ctx.storage.sql.exec(
          `
          SELECT seq, event_id, client_id, sender_node, ciphertext, created_at
          FROM messages
          ORDER BY seq DESC
          LIMIT ?
          `,
          limit,
        ),
      ].reverse();

      return json({
        terminal_id: terminalId,
        messages: rows,
      });
    }

    if (!url.pathname.endsWith("/socket")) {
      return json({ error: "ROOM_ROUTE_NOT_FOUND" }, 404);
    }

    if (request.headers.get("Upgrade")?.toLowerCase() !== "websocket") {
      return json({ error: "WEBSOCKET_REQUIRED" }, 426, {
        upgrade: "websocket",
      });
    }

    const nodeId = safeId(url.searchParams.get("node"));
    if (!nodeId) {
      return json({ error: "NODE_ID_REQUIRED" }, 400);
    }

    const pair = new WebSocketPair();
    const client = pair[0];
    const server = pair[1];

    this.ctx.acceptWebSocket(server, [terminalId, nodeId]);

    server.send(
      JSON.stringify({
        type: "channel_ready",
        protocol: 1,
        terminal_id: terminalId,
        node_id: nodeId,
        server_time: nowISO(),
      }),
    );

    return new Response(null, {
      status: 101,
      webSocket: client,
    });
  }

  async webSocketMessage(ws, message) {
    try {
      const raw =
        typeof message === "string"
          ? message
          : new TextDecoder().decode(message);

      if (new TextEncoder().encode(raw).byteLength > MAX_FRAME_BYTES) {
        ws.send(JSON.stringify({ type: "error", code: "FRAME_TOO_LARGE" }));
        return;
      }

      const frame = JSON.parse(raw);

      if (frame?.type === "ping") {
        ws.send(
          JSON.stringify({
            type: "pong",
            server_time: nowISO(),
          }),
        );
        return;
      }

      if (frame?.type !== "message") {
        ws.send(JSON.stringify({ type: "error", code: "UNSUPPORTED_FRAME" }));
        return;
      }

      const clientId = safeId(frame.client_id, 128);
      const senderNode = safeId(frame.sender_node, 96);
      const ciphertext =
        typeof frame.ciphertext === "string" ? frame.ciphertext : null;

      if (!clientId || !senderNode || !ciphertext || ciphertext.length > 60000) {
        ws.send(JSON.stringify({ type: "error", code: "INVALID_MESSAGE_FRAME" }));
        return;
      }

      // Transport contract is ciphertext-only. A plaintext field is rejected.
      if ("plaintext" in frame || "text" in frame || "body" in frame) {
        ws.send(JSON.stringify({ type: "error", code: "PLAINTEXT_REJECTED" }));
        return;
      }

      const eventId = randomEventId();
      const createdAt = nowISO();

      try {
        this.ctx.storage.sql.exec(
          `
          INSERT INTO messages(event_id, client_id, sender_node, ciphertext, created_at)
          VALUES (?, ?, ?, ?, ?)
          `,
          eventId,
          clientId,
          senderNode,
          ciphertext,
          createdAt,
        );
      } catch (error) {
        // Idempotent client retry: if the same client_id already exists,
        // return the original persisted event instead of duplicating it.
        const existing = [
          ...this.ctx.storage.sql.exec(
            `
            SELECT seq, event_id, client_id, sender_node, ciphertext, created_at
            FROM messages
            WHERE client_id = ?
            ORDER BY seq DESC
            LIMIT 1
            `,
            clientId,
          ),
        ][0];

        if (existing) {
          ws.send(
            JSON.stringify({
              type: "server_ack",
              duplicate: true,
              ...existing,
            }),
          );
          return;
        }

        throw error;
      }

      const persisted = [
        ...this.ctx.storage.sql.exec(
          `
          SELECT seq, event_id, client_id, sender_node, ciphertext, created_at
          FROM messages
          WHERE event_id = ?
          LIMIT 1
          `,
          eventId,
        ),
      ][0];

      const outbound = JSON.stringify({
        type: "message",
        ...persisted,
      });

      // ACK the sender after persistence.
      ws.send(
        JSON.stringify({
          type: "server_ack",
          duplicate: false,
          event_id: eventId,
          client_id: clientId,
          seq: persisted.seq,
          created_at: createdAt,
        }),
      );

      // Fan out to every other active participant in this terminal.
      for (const peer of this.ctx.getWebSockets()) {
        if (peer === ws) continue;
        try {
          peer.send(outbound);
        } catch {
          // Dead sockets are cleaned up by the runtime close/error callbacks.
        }
      }
    } catch (error) {
      ws.send(
        JSON.stringify({
          type: "error",
          code: "FRAME_REJECTED",
        }),
      );
    }
  }

  async webSocketClose(ws, code, reason, wasClean) {
    try {
      ws.close(code, reason);
    } catch {}
  }

  async webSocketError(ws) {
    try {
      ws.close(1011, "socket_error");
    } catch {}
  }
}
