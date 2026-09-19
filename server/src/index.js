const MAX_MESSAGE_BYTES = 32 * 1024;
const HISTORY_LIMIT = 100;

function json(data, status = 200, headers = {}) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
      ...headers,
    },
  });
}

function nowISO() {
  return new Date().toISOString();
}

function safeNode(value) {
  if (typeof value !== "string") return null;
  const v = value.trim();
  return /^node_[A-Fa-f0-9]{8,64}$/.test(v) ? v : null;
}

function safeHandle(value) {
  if (typeof value !== "string") return null;
  const v = value.trim().toLowerCase().replace(/^@/, "");
  return /^[a-z0-9_]{3,24}$/.test(v) ? v : null;
}

function safeTerminal(value) {
  if (typeof value !== "string") return null;
  const v = value.trim();
  return /^term_[A-Za-z0-9-]{8,80}$/.test(v) ? v : null;
}

async function readJSON(request) {
  try {
    return await request.json();
  } catch {
    return null;
  }
}

function networkStub(env) {
  return env.NETWORK.get(env.NETWORK.idFromName("console-network-v1"));
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === "GET" && url.pathname === "/health") {
      return json({
        service: "console-realtime",
        status: "READY",
        version: "0.2.0-alpha",
        e2ee: false,
        time: nowISO(),
      });
    }

    if (
      url.pathname.startsWith("/v1/identities") ||
      url.pathname.startsWith("/v1/handshakes") ||
      (url.pathname === "/v1/terminals" && request.method === "GET")
    ) {
      return networkStub(env).fetch(request);
    }

    const match = url.pathname.match(/^\/v1\/terminals\/([^/]+)\/(socket|history)$/);
    if (!match) {
      return json({ error: "ROUTE_NOT_FOUND" }, 404);
    }

    const terminalID = safeTerminal(decodeURIComponent(match[1]));
    if (!terminalID) return json({ error: "INVALID_TERMINAL_ID" }, 400);

    const room = env.TERMINALS.get(env.TERMINALS.idFromName(terminalID));
    const forwarded = new Request(request);
    forwarded.headers.set("x-console-terminal-id", terminalID);
    return room.fetch(forwarded);
  },
};

export class NetworkRegistry {
  constructor(ctx, env) {
    this.ctx = ctx;
    this.env = env;

    this.ctx.blockConcurrencyWhile(async () => {
      this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS identities (
          node_id TEXT PRIMARY KEY,
          handle TEXT NOT NULL UNIQUE,
          public_key TEXT NOT NULL,
          fingerprint TEXT NOT NULL,
          created_at TEXT NOT NULL
        );
      `);

      this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS handshakes (
          id TEXT PRIMARY KEY,
          from_node TEXT NOT NULL,
          to_node TEXT NOT NULL,
          state TEXT NOT NULL,
          created_at TEXT NOT NULL,
          decided_at TEXT
        );
      `);

      this.ctx.storage.sql.exec(`
        CREATE INDEX IF NOT EXISTS idx_handshakes_to
        ON handshakes(to_node, state, created_at DESC);
      `);

      this.ctx.storage.sql.exec(`
        CREATE INDEX IF NOT EXISTS idx_handshakes_from
        ON handshakes(from_node, state, created_at DESC);
      `);

      this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS terminals (
          id TEXT PRIMARY KEY,
          created_at TEXT NOT NULL,
          last_message_at TEXT
        );
      `);

      this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS terminal_members (
          terminal_id TEXT NOT NULL,
          node_id TEXT NOT NULL,
          PRIMARY KEY (terminal_id, node_id)
        );
      `);

      this.ctx.storage.sql.exec(`
        CREATE INDEX IF NOT EXISTS idx_terminal_members_node
        ON terminal_members(node_id);
      `);
    });
  }

  async fetch(request) {
    const url = new URL(request.url);

    if (request.method === "POST" && url.pathname === "/v1/identities/register") {
      return this.registerIdentity(request);
    }

    if (request.method === "GET" && url.pathname === "/v1/identities/search") {
      return this.searchIdentities(url);
    }

    if (request.method === "POST" && url.pathname === "/v1/handshakes") {
      return this.createHandshake(request);
    }

    if (request.method === "GET" && url.pathname === "/v1/handshakes") {
      return this.listHandshakes(url);
    }

    const decision = url.pathname.match(/^\/v1\/handshakes\/([^/]+)\/decision$/);
    if (request.method === "POST" && decision) {
      return this.decideHandshake(decision[1], request);
    }

    if (request.method === "GET" && url.pathname === "/v1/terminals") {
      return this.listTerminals(url);
    }

    if (request.method === "GET" && url.pathname === "/internal/membership") {
      return this.membership(url);
    }

    if (request.method === "POST" && url.pathname === "/internal/touch-terminal") {
      return this.touchTerminal(request);
    }

    return json({ error: "NETWORK_ROUTE_NOT_FOUND" }, 404);
  }

  async registerIdentity(request) {
    const body = await readJSON(request);
    const node = safeNode(body?.node_id);
    const handle = safeHandle(body?.handle);
    const publicKey = typeof body?.public_key === "string" ? body.public_key : null;
    const fingerprint = typeof body?.fingerprint === "string" ? body.fingerprint : null;

    if (!node || !handle || !publicKey || !fingerprint) {
      return json({ error: "INVALID_IDENTITY" }, 400);
    }

    const existingHandle = [
      ...this.ctx.storage.sql.exec(
        `SELECT node_id FROM identities WHERE handle = ? LIMIT 1`,
        handle,
      ),
    ][0];

    if (existingHandle && existingHandle.node_id !== node) {
      return json({ error: "HANDLE_TAKEN" }, 409);
    }

    const createdAt = nowISO();

    this.ctx.storage.sql.exec(
      `
      INSERT INTO identities(node_id, handle, public_key, fingerprint, created_at)
      VALUES (?, ?, ?, ?, ?)
      ON CONFLICT(node_id) DO UPDATE SET
        handle = excluded.handle,
        public_key = excluded.public_key,
        fingerprint = excluded.fingerprint
      `,
      node,
      handle,
      publicKey,
      fingerprint,
      createdAt,
    );

    return json({
      node_id: node,
      handle,
      public_key: publicKey,
      fingerprint,
    });
  }

  async searchIdentities(url) {
    const raw = (url.searchParams.get("q") || "").trim().toLowerCase();
    const q = raw.replace(/^@/, "");

    if (q.length < 2) return json({ identities: [] });

    const rows = [
      ...this.ctx.storage.sql.exec(
        `
        SELECT node_id, handle, public_key, fingerprint
        FROM identities
        WHERE handle LIKE ? OR lower(node_id) LIKE ?
        ORDER BY
          CASE WHEN handle = ? THEN 0 ELSE 1 END,
          handle ASC
        LIMIT 20
        `,
        `%${q}%`,
        `%${q}%`,
        q,
      ),
    ];

    return json({ identities: rows });
  }

  async createHandshake(request) {
    const body = await readJSON(request);
    const fromNode = safeNode(body?.from_node);
    const toNode = safeNode(body?.to_node);

    if (!fromNode || !toNode || fromNode === toNode) {
      return json({ error: "INVALID_HANDSHAKE" }, 400);
    }

    const target = [
      ...this.ctx.storage.sql.exec(
        `SELECT node_id FROM identities WHERE node_id = ? LIMIT 1`,
        toNode,
      ),
    ][0];

    if (!target) return json({ error: "NODE_NOT_FOUND" }, 404);

    const existingTerminal = [
      ...this.ctx.storage.sql.exec(
        `
        SELECT tm1.terminal_id AS id
        FROM terminal_members tm1
        JOIN terminal_members tm2 ON tm1.terminal_id = tm2.terminal_id
        WHERE tm1.node_id = ? AND tm2.node_id = ?
        LIMIT 1
        `,
        fromNode,
        toNode,
      ),
    ][0];

    if (existingTerminal) {
      return json({ error: "TERMINAL_ALREADY_EXISTS", terminal_id: existingTerminal.id }, 409);
    }

    const pending = [
      ...this.ctx.storage.sql.exec(
        `
        SELECT id, from_node, to_node, state, created_at
        FROM handshakes
        WHERE state = 'pending'
          AND ((from_node = ? AND to_node = ?) OR (from_node = ? AND to_node = ?))
        LIMIT 1
        `,
        fromNode,
        toNode,
        toNode,
        fromNode,
      ),
    ][0];

    if (pending) return json(pending);

    const item = {
      id: crypto.randomUUID(),
      from_node: fromNode,
      to_node: toNode,
      state: "pending",
      created_at: nowISO(),
    };

    this.ctx.storage.sql.exec(
      `INSERT INTO handshakes(id, from_node, to_node, state, created_at) VALUES (?, ?, ?, ?, ?)`,
      item.id,
      item.from_node,
      item.to_node,
      item.state,
      item.created_at,
    );

    return json(item, 201);
  }

  async listHandshakes(url) {
    const node = safeNode(url.searchParams.get("node"));
    if (!node) return json({ error: "NODE_REQUIRED" }, 400);

    const incomingRows = [
      ...this.ctx.storage.sql.exec(
        `
        SELECT h.id, h.from_node, h.to_node, h.state, h.created_at,
               i.node_id AS peer_node_id, i.handle AS peer_handle,
               i.public_key AS peer_public_key, i.fingerprint AS peer_fingerprint
        FROM handshakes h
        LEFT JOIN identities i ON i.node_id = h.from_node
        WHERE h.to_node = ? AND h.state = 'pending'
        ORDER BY h.created_at DESC
        LIMIT 50
        `,
        node,
      ),
    ];

    const outgoingRows = [
      ...this.ctx.storage.sql.exec(
        `
        SELECT h.id, h.from_node, h.to_node, h.state, h.created_at,
               i.node_id AS peer_node_id, i.handle AS peer_handle,
               i.public_key AS peer_public_key, i.fingerprint AS peer_fingerprint
        FROM handshakes h
        LEFT JOIN identities i ON i.node_id = h.to_node
        WHERE h.from_node = ? AND h.state = 'pending'
        ORDER BY h.created_at DESC
        LIMIT 50
        `,
        node,
      ),
    ];

    const map = (row) => ({
      id: row.id,
      from_node: row.from_node,
      to_node: row.to_node,
      state: row.state,
      created_at: row.created_at,
      peer: row.peer_node_id
        ? {
            node_id: row.peer_node_id,
            handle: row.peer_handle,
            public_key: row.peer_public_key,
            fingerprint: row.peer_fingerprint,
          }
        : null,
    });

    return json({
      incoming: incomingRows.map(map),
      outgoing: outgoingRows.map(map),
    });
  }

  async decideHandshake(id, request) {
    const body = await readJSON(request);
    const node = safeNode(body?.node_id);
    const decision = body?.decision;

    if (!node || !["accepted", "rejected"].includes(decision)) {
      return json({ error: "INVALID_DECISION" }, 400);
    }

    const handshake = [
      ...this.ctx.storage.sql.exec(
        `
        SELECT id, from_node, to_node, state, created_at
        FROM handshakes
        WHERE id = ?
        LIMIT 1
        `,
        id,
      ),
    ][0];

    if (!handshake) return json({ error: "HANDSHAKE_NOT_FOUND" }, 404);
    if (handshake.to_node !== node) return json({ error: "ACCESS_DENIED" }, 403);
    if (handshake.state !== "pending") return json({ error: "HANDSHAKE_CLOSED" }, 409);

    this.ctx.storage.sql.exec(
      `UPDATE handshakes SET state = ?, decided_at = ? WHERE id = ?`,
      decision,
      nowISO(),
      id,
    );

    if (decision === "rejected") {
      return json({ state: "rejected", terminal: null });
    }

    const terminalID = `term_${crypto.randomUUID()}`;
    const createdAt = nowISO();

    this.ctx.storage.sql.exec(
      `INSERT INTO terminals(id, created_at, last_message_at) VALUES (?, ?, NULL)`,
      terminalID,
      createdAt,
    );

    this.ctx.storage.sql.exec(
      `INSERT INTO terminal_members(terminal_id, node_id) VALUES (?, ?), (?, ?)`,
      terminalID,
      handshake.from_node,
      terminalID,
      handshake.to_node,
    );

    const peer = [
      ...this.ctx.storage.sql.exec(
        `
        SELECT node_id, handle, public_key, fingerprint
        FROM identities WHERE node_id = ? LIMIT 1
        `,
        handshake.from_node,
      ),
    ][0];

    return json({
      state: "accepted",
      terminal: {
        id: terminalID,
        created_at: createdAt,
        last_message_at: null,
        peer,
      },
    });
  }

  async listTerminals(url) {
    const node = safeNode(url.searchParams.get("node"));
    if (!node) return json({ error: "NODE_REQUIRED" }, 400);

    const rows = [
      ...this.ctx.storage.sql.exec(
        `
        SELECT t.id, t.created_at, t.last_message_at,
               i.node_id AS peer_node_id, i.handle AS peer_handle,
               i.public_key AS peer_public_key, i.fingerprint AS peer_fingerprint
        FROM terminals t
        JOIN terminal_members mine
          ON mine.terminal_id = t.id AND mine.node_id = ?
        JOIN terminal_members other
          ON other.terminal_id = t.id AND other.node_id != ?
        JOIN identities i
          ON i.node_id = other.node_id
        ORDER BY COALESCE(t.last_message_at, t.created_at) DESC
        LIMIT 200
        `,
        node,
        node,
      ),
    ];

    return json({
      terminals: rows.map((row) => ({
        id: row.id,
        created_at: row.created_at,
        last_message_at: row.last_message_at,
        peer: {
          node_id: row.peer_node_id,
          handle: row.peer_handle,
          public_key: row.peer_public_key,
          fingerprint: row.peer_fingerprint,
        },
      })),
    });
  }

  async membership(url) {
    const terminalID = safeTerminal(url.searchParams.get("terminal_id"));
    const node = safeNode(url.searchParams.get("node"));

    if (!terminalID || !node) return json({ member: false }, 400);

    const row = [
      ...this.ctx.storage.sql.exec(
        `
        SELECT 1 AS ok FROM terminal_members
        WHERE terminal_id = ? AND node_id = ?
        LIMIT 1
        `,
        terminalID,
        node,
      ),
    ][0];

    return json({ member: Boolean(row) });
  }

  async touchTerminal(request) {
    const body = await readJSON(request);
    const terminalID = safeTerminal(body?.terminal_id);
    if (!terminalID) return json({ ok: false }, 400);

    this.ctx.storage.sql.exec(
      `UPDATE terminals SET last_message_at = ? WHERE id = ?`,
      nowISO(),
      terminalID,
    );

    return json({ ok: true });
  }
}

export class TerminalRoom {
  constructor(ctx, env) {
    this.ctx = ctx;
    this.env = env;

    this.ctx.blockConcurrencyWhile(async () => {
      this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS messages (
          seq INTEGER PRIMARY KEY AUTOINCREMENT,
          event_id TEXT NOT NULL UNIQUE,
          client_id TEXT NOT NULL UNIQUE,
          sender_node TEXT NOT NULL,
          content TEXT NOT NULL,
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
    const terminalID = request.headers.get("x-console-terminal-id");
    const node = safeNode(url.searchParams.get("node"));

    if (!terminalID || !node) {
      return json({ error: "TERMINAL_OR_NODE_REQUIRED" }, 400);
    }

    const membershipURL = new URL("https://network/internal/membership");
    membershipURL.searchParams.set("terminal_id", terminalID);
    membershipURL.searchParams.set("node", node);

    const membership = await networkStub(this.env).fetch(membershipURL);
    const membershipData = await membership.json();

    if (!membershipData.member) {
      return json({ error: "ACCESS_DENIED" }, 403);
    }

    if (url.pathname.endsWith("/history") && request.method === "GET") {
      const limit = Math.max(
        1,
        Math.min(HISTORY_LIMIT, Number(url.searchParams.get("limit") || 50)),
      );

      const rows = [
        ...this.ctx.storage.sql.exec(
          `
          SELECT seq, event_id, client_id, sender_node, content, created_at
          FROM messages
          ORDER BY seq DESC
          LIMIT ?
          `,
          limit,
        ),
      ].reverse();

      return json({
        terminal_id: terminalID,
        messages: rows,
      });
    }

    if (!url.pathname.endsWith("/socket")) {
      return json({ error: "ROOM_ROUTE_NOT_FOUND" }, 404);
    }

    if (request.headers.get("Upgrade")?.toLowerCase() !== "websocket") {
      return json({ error: "WEBSOCKET_REQUIRED" }, 426, { upgrade: "websocket" });
    }

    const pair = new WebSocketPair();
    const client = pair[0];
    const server = pair[1];

    this.ctx.acceptWebSocket(server, [terminalID, node]);

    server.send(JSON.stringify({
      type: "channel_ready",
      protocol: 1,
      terminal_id: terminalID,
      node_id: node,
      security: "internal-alpha-no-e2ee",
      server_time: nowISO(),
    }));

    return new Response(null, { status: 101, webSocket: client });
  }

  async webSocketMessage(ws, message) {
    try {
      const raw =
        typeof message === "string"
          ? message
          : new TextDecoder().decode(message);

      if (new TextEncoder().encode(raw).byteLength > MAX_MESSAGE_BYTES) {
        ws.send(JSON.stringify({ type: "error", code: "FRAME_TOO_LARGE" }));
        return;
      }

      const frame = JSON.parse(raw);

      if (frame?.type === "ping") {
        ws.send(JSON.stringify({ type: "pong", server_time: nowISO() }));
        return;
      }

      if (frame?.type !== "message") {
        ws.send(JSON.stringify({ type: "error", code: "UNSUPPORTED_FRAME" }));
        return;
      }

      const clientID =
        typeof frame.client_id === "string" && frame.client_id.length <= 128
          ? frame.client_id
          : null;
      const senderNode = safeNode(frame.sender_node);
      const content =
        typeof frame.content === "string" ? frame.content.trim() : null;

      if (!clientID || !senderNode || !content || content.length > 10000) {
        ws.send(JSON.stringify({ type: "error", code: "INVALID_MESSAGE_FRAME" }));
        return;
      }

      const existing = [
        ...this.ctx.storage.sql.exec(
          `
          SELECT seq, event_id, client_id, sender_node, content, created_at
          FROM messages WHERE client_id = ? LIMIT 1
          `,
          clientID,
        ),
      ][0];

      if (existing) {
        ws.send(JSON.stringify({
          type: "server_ack",
          duplicate: true,
          event_id: existing.event_id,
          client_id: existing.client_id,
          seq: existing.seq,
          created_at: existing.created_at,
        }));
        return;
      }

      const eventID = crypto.randomUUID();
      const createdAt = nowISO();

      this.ctx.storage.sql.exec(
        `
        INSERT INTO messages(event_id, client_id, sender_node, content, created_at)
        VALUES (?, ?, ?, ?, ?)
        `,
        eventID,
        clientID,
        senderNode,
        content,
        createdAt,
      );

      const persisted = [
        ...this.ctx.storage.sql.exec(
          `
          SELECT seq, event_id, client_id, sender_node, content, created_at
          FROM messages WHERE event_id = ? LIMIT 1
          `,
          eventID,
        ),
      ][0];

      ws.send(JSON.stringify({
        type: "server_ack",
        duplicate: false,
        event_id: eventID,
        client_id: clientID,
        seq: persisted.seq,
        created_at: createdAt,
      }));

      const outbound = JSON.stringify({
        type: "message",
        ...persisted,
      });

      for (const peer of this.ctx.getWebSockets()) {
        if (peer === ws) continue;
        try {
          peer.send(outbound);
        } catch {}
      }

      const tags = this.ctx.getTags(ws);
      const terminalID = tags[0];
      if (terminalID) {
        await networkStub(this.env).fetch(
          new Request("https://network/internal/touch-terminal", {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: JSON.stringify({ terminal_id: terminalID }),
          }),
        );
      }
    } catch {
      ws.send(JSON.stringify({ type: "error", code: "FRAME_REJECTED" }));
    }
  }

  async webSocketClose(ws, code, reason) {
    try { ws.close(code, reason); } catch {}
  }

  async webSocketError(ws) {
    try { ws.close(1011, "socket_error"); } catch {}
  }
}
