import { defineConfig, type Plugin } from 'vite';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import { existsSync } from 'fs';

const __dirname = dirname(fileURLToPath(import.meta.url));

// MPA用のディレクトリアクセスをindex.htmlにリダイレクトするプラグイン
function mpaFallback(): Plugin {
  return {
    name: 'mpa-fallback',
    configureServer(server) {
      server.middlewares.use((req, _res, next) => {
        if (req.url && !req.url.includes('.') && !req.url.endsWith('/')) {
          // Check if directory/index.html exists
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
  plugins: [mpaFallback()],
  build: {
    rollupOptions: {
      input: {
        index: resolve(__dirname, './index.html'),
        "playground/spa": resolve(__dirname, './playground/spa/index.html'),
        "playground/browser_app": resolve(__dirname, './playground/browser_app/index.html'),
      },
    },
  },
});
