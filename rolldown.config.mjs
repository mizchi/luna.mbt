import { defineConfig } from 'rolldown';

export default defineConfig([
  // ESM build with code splitting
  {
    input: {
      'loader': './js/loader/src/loader.ts',
      'wc-loader': './js/loader/src/wc-loader.ts',
      'sol-nav': './js/loader/src/sol-nav.ts',
      'lib': './js/loader/src/lib.ts',
    },
    output: {
      dir: './js/loader/dist',
      format: 'esm',
      entryFileNames: '[name].js',
    },
    minify: true,
  },
  // IIFE bundled builds (self-contained, for testing and static serving)
  {
    input: './js/loader/src/loader.ts',
    output: {
      file: './js/loader/dist/loader.iife.js',
      format: 'iife',
    },
    minify: true,
  },
  {
    input: './js/loader/src/wc-loader.ts',
    output: {
      file: './js/loader/dist/wc-loader.iife.js',
      format: 'iife',
    },
    minify: true,
  },
]);
