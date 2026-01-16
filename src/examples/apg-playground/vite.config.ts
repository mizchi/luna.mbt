import { defineConfig } from 'vite';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectRoot = resolve(__dirname, '../../..');

export default defineConfig({
  root: __dirname,
  resolve: {
    alias: {
      '/target': resolve(projectRoot, 'target'),
    },
  },
  server: {
    port: 4101,
    fs: {
      allow: [projectRoot],
    },
  },
});
