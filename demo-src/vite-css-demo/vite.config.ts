import { defineConfig } from "vite";
import path from "path";
import { lunaCss } from "../../js/luna/src/vite-plugin";

export default defineConfig({
  plugins: [
    lunaCss({
      // Absolute paths work
      src: [path.resolve(__dirname, "../../src/examples/todomvc")],
      verbose: true,
      // Enable experimental CSS co-occurrence optimization
      experimental: {
        optimize: true,
        optimizeMinFrequency: 2,
      },
    }),
  ],
});
