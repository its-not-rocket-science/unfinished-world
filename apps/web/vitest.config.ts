import { defineConfig } from 'vitest/config';

export default defineConfig({
  // Vitest is powered by Vite; this config is a Vite config
  test: {
    environment: 'jsdom',
    setupFiles: ['./vitest.setup.ts'],
    include: ['src/**/*.test.{ts,tsx}'],
    coverage: {
      provider: 'v8',
      reports: ['text', 'lcov'],
    },
  },
  // This is the key bit: use the automatic JSX transform (react/jsx-runtime),
  // so we don't need `import React` in scope.
  esbuild: {
    jsx: 'automatic',
    jsxImportSource: 'react',
  },
});
