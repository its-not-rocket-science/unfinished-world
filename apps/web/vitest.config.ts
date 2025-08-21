import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'jsdom',
    setupFiles: ['./vitest.setup.ts'],
    globals: true,
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html'],
      include: ['src/**/*.{ts,tsx}'],
      exclude: ['next.config.ts', 'src/app/layout.tsx', '**/*.d.ts'],
      thresholds: { statements: 70, branches: 65, functions: 65, lines: 70 },
      reportsDirectory: './coverage'
    },
  },
  esbuild: {
    jsx: 'automatic',
    jsxImportSource: 'react',
  },
});
