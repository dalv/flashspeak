import { generateJSON, UpstreamError } from "./anthropic.js";
import { legacy } from "./legacy.js";
import * as v2 from "./v2/handlers.js";

// Routes:
//   POST /              legacy 1.x endpoint, unchanged (decision 0008)
//   POST /v2/translate  POST /v2/clarify  POST /v2/suggest  POST /v2/flag
//   GET  /v2/config
// No auth or server-side limits until the App Store release (decision 0010).

const JSON_HEADERS = { "Content-Type": "application/json" };

function json(body, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: JSON_HEADERS });
}

const POST_ROUTES = {
  "/v2/translate": v2.translate,
  "/v2/clarify": v2.clarify,
  "/v2/suggest": v2.suggest,
};

export default {
  async fetch(request, env) {
    const { pathname } = new URL(request.url);

    if (pathname === "/" || pathname === "") {
      return legacy.fetch(request, env);
    }

    if (request.method === "GET" && pathname === "/v2/config") {
      return json(v2.config());
    }

    if (request.method !== "POST") {
      return json({ error: "Method not allowed" }, 405);
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return json({ error: "Body must be JSON" }, 400);
    }

    try {
      if (pathname === "/v2/flag") {
        return json(v2.flag(body));
      }
      const handler = POST_ROUTES[pathname];
      if (!handler) {
        return json({ error: "Not found" }, 404);
      }
      const generate = (options) => generateJSON(env, options);
      return json(await handler(body, generate));
    } catch (error) {
      if (error instanceof v2.BadRequest) {
        return json({ error: error.message }, 400);
      }
      if (error instanceof UpstreamError) {
        return json({ error: error.message }, error.status);
      }
      console.error("Worker error", error);
      return json({ error: "Internal server error" }, 500);
    }
  },
};
