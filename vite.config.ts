import { defineConfig } from 'vite';
import { resolve } from 'path';
import { moonbit } from 'vite-plugin-moonbit';
import { lunaCss } from './js/luna/dist/vite-plugin.js';

const rootDir = import.meta.dirname;

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
        '/target': resolve(rootDir, 'target'),
        '@luna/loader': resolve(rootDir, 'js/loader/dist'),
      },
    },
    server: {
      fs: {
        allow: [rootDir],
      },
    },
    build: {
      outDir: 'dist',
      emptyOutDir: true,
      rollupOptions: {
        input: {
          index: resolve(rootDir, 'index.html'),
          hello_luna: resolve(rootDir, 'src/examples/hello_luna/index.html'),
          spa: resolve(rootDir, 'src/examples/spa/index.html'),
          browser_router: resolve(rootDir, 'src/examples/browser_router/index.html'),
          game: resolve(rootDir, 'src/examples/game/index.html'),
          wc: resolve(rootDir, 'src/examples/wc/index.html'),
          todomvc: resolve(rootDir, 'src/examples/todomvc/index.html'),
          css_split_test: resolve(rootDir, 'src/examples/css_split_test/index.html'),
          'apg-playground': resolve(rootDir, 'src/examples/apg-playground/index.html'),
        },
      },
    },
  };
});
