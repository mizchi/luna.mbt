import { defineConfig } from 'vite';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectRoot = resolve(__dirname, '../../..');

export default defineConfig({
  root: __dirname,
  resolve: {
    alias: {
      '/_build': resolve(projectRoot, '_build'),
    },
  },
  server: {
    port: 4101,
    fs: {
      allow: [projectRoot],
    },
  },
});
