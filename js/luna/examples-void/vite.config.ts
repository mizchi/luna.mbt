import { defineConfig } from "vite";
import { voidPlugin } from "void";
import { voidLuna } from "@luna_ui/luna/void";
import solid from "vite-plugin-solid";

const react = [
  "react",
  "react/jsx-runtime",
  "react/jsx-dev-runtime",
  "react-dom",
  "react-dom/client",
  "react-dom/server",
];

export default defineConfig({
  plugins: [
    voidPlugin(),
    voidLuna({
      islands: {
        luna: "./src/counter.luna.tsx",
        react: "./src/react-island.ts",
        solid: "./src/solid-island.ts",
      },
    }),
    solid({ include: /\.solid\.tsx$/, ssr: true }),
  ],
  resolve: { dedupe: ["react", "react-dom", "solid-js"] },
  optimizeDeps: { entries: ["src/**/*"], include: [...react, "solid-js", "solid-js/web"] },
  ssr: { noExternal: ["react", "react-dom"], optimizeDeps: { include: react } },
  environments: {
    void_worker: {
      optimizeDeps: {
        entries: ["pages/**/*.tsx"],
        include: [...react, "solid-js", "solid-js/web", "zod"],
      },
    },
  },
});
