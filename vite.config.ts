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
    base: isDev ? '/' : '/demo/',
    resolve: {
      alias: {
        '/target': resolve(__dirname, 'target'),
        '@luna/loader': resolve(__dirname, 'js/loader/dist'),
      },
    },
    server: {
      fs: {
        allow: [__dirname],
      },
    },
    build: {
      outDir: 'dist',
      emptyOutDir: true,
      rollupOptions: {
        input: {
          index: resolve(__dirname, 'index.html'),
          hello_luna: resolve(__dirname, 'src/examples/hello_luna/index.html'),
          spa: resolve(__dirname, 'src/examples/spa/index.html'),
          browser_router: resolve(__dirname, 'src/examples/browser_router/index.html'),
          game: resolve(__dirname, 'src/examples/game/index.html'),
          wc: resolve(__dirname, 'src/examples/wc/index.html'),
          todomvc: resolve(__dirname, 'src/examples/todomvc/index.html'),
          css_split_test: resolve(__dirname, 'src/examples/css_split_test/index.html'),
          'apg-playground': resolve(__dirname, 'src/examples/apg-playground/index.html'),
        },
      },
    },
  };
});
