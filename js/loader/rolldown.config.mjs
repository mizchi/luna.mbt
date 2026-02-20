import { defineConfig } from 'rolldown';

export default defineConfig([
  // ESM build with code splitting
  {
    input: {
      'loader': './src/loader.ts',
      'wc-loader': './src/wc-loader.ts',
      'sol-nav': './src/sol-nav.ts',
      'lib': './src/lib.ts',
      'hydration': './src/hydration.ts',
      // Boot runtime (chunk loader + minimal router)
      'boot/index': './src/boot/index.ts',
      'boot/loader': './src/boot/loader.ts',
      'boot/router': './src/boot/router.ts',
      // Extended routers (Phase 7)
      'router/index': './src/router/index.ts',
      'router/hybrid': './src/router/hybrid.ts',
      'router/spa': './src/router/spa.ts',
      'router/scroll': './src/router/scroll.ts',
      'router/navigation': './src/router/navigation.ts',
      'router/navigation-fallback': './src/router/navigation-fallback.ts',
    },
    output: {
      dir: './dist',
      format: 'esm',
      entryFileNames: '[name].js',
      minify: true,
      legalComments: 'none',
    },
  },
  // IIFE bundled builds (self-contained, for testing and static serving)
  {
    input: './src/loader.ts',
    output: {
      file: './dist/loader.iife.js',
      format: 'iife',
      minify: true,
      legalComments: 'none',
    },
  },
  {
    input: './src/wc-loader.ts',
    output: {
      file: './dist/wc-loader.iife.js',
      format: 'iife',
      minify: true,
      legalComments: 'none',
    },
  },
  // HMR client (dev-only, injected by sol dev server)
  {
    input: './src/hmr-client.ts',
    output: {
      file: './dist/hmr-client.js',
      format: 'iife',
      minify: false,
    },
  },
  // Boot runtime IIFE (self-contained, for static sites)
  {
    input: './src/boot/index.ts',
    output: {
      file: './dist/boot.iife.js',
      format: 'iife',
      name: 'LunaBoot',
      minify: true,
      legalComments: 'none',
    },
  },
]);
