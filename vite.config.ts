import { defineConfig } from 'vite';
import { resolve } from 'path';
import { moonbit } from 'vite-plugin-moonbit';
import { lunaCss } from './js/luna/dist/vite-plugin.js';

const rootDir = import.meta.dirname;

export default defineConfig(({ command }) => {
  const isDev = command === 'serve';
  const moonBuildMode = isDev ? 'debug' : 'release';

  return {
    appType: 'mpa',
    plugins: [
      moonbit({ mode: moonBuildMode }),
      lunaCss({
        src: ['src/examples/todomvc', 'src/examples/css_split_test'],
        mode: 'external',
        // lunaCss expects basename without extension
        cssFileName: 'luna',
        verbose: isDev,
      }),
    ],
    base: isDev ? '/' : '/demo/',
    resolve: {
      alias: {
        // In dev, MoonBit emits to debug dir by default (moon build --watch)
        ...(isDev
          ? { '/_build/js/release/build': resolve(rootDir, '_build/js/debug/build') }
          : {}),
        '/_build': resolve(rootDir, '_build'),
        '@luna/loader': resolve(rootDir, 'js/loader/dist'),
      },
    },
    server: {
      port: 4100,
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
