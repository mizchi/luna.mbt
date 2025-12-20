import { defineConfig, type Plugin } from 'vite';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import { existsSync } from 'fs';

const __dirname = dirname(fileURLToPath(import.meta.url));

// Rewrite /demo/* requests to demo-src/*
function serveDemoSrc(): Plugin {
  return {
    name: 'serve-demo-src',
    configureServer(server) {
      server.middlewares.use((req, _res, next) => {
        if (req.url?.startsWith('/demo/')) {
          // Rewrite /demo/foo to /demo-src/foo
          req.url = req.url.replace('/demo/', '/demo-src/');
        }
        next();
      });
    },
  };
}

// MPA: redirect directory access to index.html
function mpaFallback(): Plugin {
  return {
    name: 'mpa-fallback',
    configureServer(server) {
      server.middlewares.use((req, _res, next) => {
        if (req.url && !req.url.includes('.') && !req.url.endsWith('/')) {
          const indexPath = resolve(__dirname, '.' + req.url, 'index.html');
          if (existsSync(indexPath)) {
            req.url = req.url + '/index.html';
          }
        }
        next();
      });
    },
  };
}

export default defineConfig({
  appType: 'mpa',
  plugins: [serveDemoSrc(), mpaFallback()],
  // Use project root so target/ is accessible
  root: '.',
  base: '/',
  build: {
    outDir: 'docs/public/demo',
    emptyOutDir: true,
    rollupOptions: {
      input: {
        "index": resolve(__dirname, './demo-src/index.html'),
        "spa": resolve(__dirname, './demo-src/spa/index.html'),
        "browser_router": resolve(__dirname, './demo-src/browser_router/index.html'),
        "game": resolve(__dirname, './demo-src/game/index.html'),
        "wc": resolve(__dirname, './demo-src/wc/index.html'),
      },
    },
  },
});
