import { defineConfig } from 'vite';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));

export default defineConfig({
  root: __dirname,
  server: {
    port: 4102,
  },
  resolve: {
    alias: {
      '@luna_ui/wcr': resolve(__dirname, '../../../js/wcr/src/index.ts'),
    },
  },
});
