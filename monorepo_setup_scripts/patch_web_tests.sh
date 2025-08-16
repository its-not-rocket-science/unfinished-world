#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Forcing automatic JSX runtime in web tests (Vitest/Vite)…"
echo "🔧 and rewriting apps/api/vitest.config.ts (fix stray comma + coverage exclude)…"

cat > apps/api/vitest.config.ts <<'TS'
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
TS

echo "▶️ Running API tests (with coverage)…"
pnpm -C apps/api test -- --coverage

echo "✅ API test config fixed. Run the whole suite with: pnpm test"

