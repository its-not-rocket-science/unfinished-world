import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'node',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html'],
      include: ['src/**/*.{ts,tsx}'],
      exclude: [
        // exclude glue/CLI/browser-only entrypoints from coverage %
        'src/cli.ts',
        'src/client.ts',
        'src/index.ts',
        'src/io.node.ts',
        'src/demo.ts',
        '**/*.d.ts',
        'test/**'
      ],
    },
  },
});
