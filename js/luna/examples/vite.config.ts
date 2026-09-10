import { defineConfig } from "vite";

export default defineConfig({
  root: './',
  build: {
    outDir: 'dist',
    rolldownOptions: {
      input: ['index.html', 'animation.html'],
    },
  },
});
