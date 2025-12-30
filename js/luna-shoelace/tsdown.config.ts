import { defineConfig } from 'tsdown';

export default defineConfig({
  entry: [
    'src/index.ts',
    'src/button.ts',
    'src/input.ts',
    'src/checkbox.ts',
    'src/switch.ts',
    'src/types.ts',
  ],
  format: 'esm',
  dts: true,
  clean: true,
  outDir: 'dist',
});
