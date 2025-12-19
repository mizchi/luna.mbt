import { defineConfig, type Plugin } from 'vite';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import { existsSync } from 'fs';

const __dirname = dirname(fileURLToPath(import.meta.url));

// MPA用のディレクトリアクセスをindex.htmlにリダイレクトするプラグイン
function mpaFallback(): Plugin {
  const middleware = (baseDir: string) => (req: any, _res: any, next: any) => {
    if (req.url && !req.url.includes('.') && !req.url.endsWith('/')) {
      // Check if directory/index.html exists
      const indexPath = resolve(baseDir, '.' + req.url, 'index.html');
      if (existsSync(indexPath)) {
        req.url = req.url + '/index.html';
      }
    }
    next();
  };

  return {
    name: 'mpa-fallback',
    configureServer(server) {
      server.middlewares.use(middleware(__dirname));
    },
    configurePreviewServer(server) {
      server.middlewares.use(middleware(resolve(__dirname, 'dist')));
    },
  };
}

export default defineConfig({
  appType: 'mpa',
  plugins: [mpaFallback()],
  root: 'demo-src',
  base: '/demo/',
  build: {
    outDir: '../docs/public/demo',
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
