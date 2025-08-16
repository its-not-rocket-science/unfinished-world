import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'node',
    include: ['test/**/*.test.ts'],
    coverage: {
      provider: 'v8',
      reports: ['text', 'lcov'],
      exclude: ['src/index.ts']
    }
  }
});
