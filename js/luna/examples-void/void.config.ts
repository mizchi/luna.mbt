import { defineConfig } from "void/config";

export default defineConfig({
  target: "cloudflare",
  auth: { providers: ["email"] },
  head: {
    htmlAttrs: { lang: "en" },
    meta: [{ name: "viewport", content: "width=device-width, initial-scale=1" }],
  },
  worker: { compatibility_date: "2026-10-18" },
});
