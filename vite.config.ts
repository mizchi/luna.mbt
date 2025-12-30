import { defineConfig } from 'vite';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import { moonbit } from 'vite-plugin-moonbit';
import { lunaCss } from './js/luna/dist/vite-plugin.js';

const __dirname = dirname(fileURLToPath(import.meta.url));

export default defineConfig(({ command }) => {
  const isDev = command === 'serve';

  return {
    appType: 'mpa',
    plugins: [
      moonbit({}),
      lunaCss({
        src: ['src/examples/todomvc', 'src/examples/css_split_test'],
        mode: 'external',
        cssFileName: 'luna.css',
        verbose: isDev,
      }),
    ],
    // Use demo-src as root for both dev and build
    root: 'demo-src',
    base: isDev ? '/' : '/demo/',
    resolve: {
      alias: {
        // Map /target to project root's target directory
        '/target': resolve(__dirname, 'target'),
      },
    },
    server: {
      fs: {
        // Allow access to project root (for target/ directory)
        allow: [__dirname],
      },
    },
    build: {
      // outDir is relative to root (demo-src), so go up one level
      outDir: '../website/public/demo',
      emptyOutDir: true,
      rollupOptions: {
        input: {
          "index": resolve(__dirname, './demo-src/index.html'),
          "hello_luna": resolve(__dirname, './demo-src/hello_luna/index.html'),
          "spa": resolve(__dirname, './demo-src/spa/index.html'),
          "browser_router": resolve(__dirname, './demo-src/browser_router/index.html'),
          "game": resolve(__dirname, './demo-src/game/index.html'),
          "wc": resolve(__dirname, './demo-src/wc/index.html'),
          "todomvc": resolve(__dirname, './demo-src/todomvc/index.html'),
          "css_split": resolve(__dirname, './demo-src/css_split/index.html'),
        },
      },
    },
  };
});
