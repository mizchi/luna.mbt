import { defineConfig } from 'vite';
import { resolve } from 'path';
import { moonbit } from 'vite-plugin-moonbit';
import { lunaCss } from '../js/luna/dist/vite-plugin.js';

// vite root dir is `luna/` (this file's directory).
// Workspace root (where `_build/`, `js/`, `node_modules/` live) is one level up.
const rootDir = import.meta.dirname;
const workspaceRoot = resolve(rootDir, '..');

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
          ? { '/_build/js/release/build': resolve(workspaceRoot, '_build/js/debug/build') }
          : {}),
        '/_build': resolve(workspaceRoot, '_build'),
        '@luna/loader': resolve(workspaceRoot, 'js/loader/dist'),
      },
    },
    server: {
      port: 4100,
      fs: {
        // Allow vite to read both luna/ and the workspace root (for _build/, js/loader/dist/, ...).
        allow: [rootDir, workspaceRoot],
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
          // apg-playground lives in the luna_components mooncake
          'apg-playground': resolve(rootDir, '..', 'luna_components', 'src', 'examples', 'apg-playground', 'index.html'),
        },
      },
    },
  };
});
