#!/usr/bin/env bash
set -euo pipefail

echo "🧪 Adding test infrastructure..."

# ────────────────────────────────────────────────────────────────────────────────
# Root: turbo pipeline + scripts
# ────────────────────────────────────────────────────────────────────────────────
# Ensure turbo is present
pnpm add -D -w turbo >/dev/null

# Add/merge test scripts into root package.json
node - <<'NODE'
const fs=require('fs');
const f='package.json';
const pkg=JSON.parse(fs.readFileSync(f,'utf8'));
pkg.scripts ||= {};
pkg.scripts.test = "turbo run test";
pkg.scripts['test:coverage'] = "turbo run test -- --coverage";
pkg.scripts.ci = "pnpm lint && pnpm typecheck && pnpm test && pnpm build";
fs.writeFileSync(f, JSON.stringify(pkg,null,2));
console.log("✓ Root scripts updated");
NODE

# Add a "test" task to turbo.json (idempotent)
node - <<'NODE'
const fs=require('fs');
const f='turbo.json';
const turbo=JSON.parse(fs.readFileSync(f,'utf8'));
turbo.pipeline ||= {};
turbo.pipeline.test ||= { dependsOn: ["^test"], outputs: ["coverage/**"] };
fs.writeFileSync(f, JSON.stringify(turbo,null,2));
console.log("✓ turbo.json: test pipeline added");
NODE

# ────────────────────────────────────────────────────────────────────────────────
# Shared package tests (packages/shared)
# ────────────────────────────────────────────────────────────────────────────────
pnpm -C packages/shared add -D vitest @vitest/coverage-v8 @types/node >/dev/null

mkdir -p packages/shared/test
cat > packages/shared/test/index.test.ts <<'TS'
import { describe, it, expect } from 'vitest';
import { greet } from '../src';

describe('shared/greet', () => {
  it('says hello', () => {
    expect(greet('web')).toBe('hello, web!');
  });
});
TS

cat > packages/shared/vitest.config.ts <<'TS'
import { defineConfig } from 'vitest/config';
export default defineConfig({
  test: {
    environment: 'node',
    include: ['test/**/*.test.ts'],
    coverage: {
      provider: 'v8',
      reports: ['text', 'lcov'],
    },
  },
});
TS

# add test scripts
node - <<'NODE'
const fs=require('fs');
const f='packages/shared/package.json';
const pkg=JSON.parse(fs.readFileSync(f,'utf8'));
pkg.scripts ||= {};
pkg.scripts.test = "vitest run";
pkg.scripts['test:watch'] = "vitest";
pkg.scripts['test:coverage'] = "vitest run --coverage";
fs.writeFileSync(f, JSON.stringify(pkg,null,2));
console.log("✓ shared: scripts updated");
NODE

# ────────────────────────────────────────────────────────────────────────────────
# API tests (apps/api) — using Fastify.inject
# ────────────────────────────────────────────────────────────────────────────────
pnpm -C apps/api add -D vitest @vitest/coverage-v8 @types/node >/dev/null

# Create app builder (so tests don't boot a server)
cat > apps/api/src/app.ts <<'TS'
import Fastify from 'fastify';
import { greet } from '@unfinished-world/shared';

export function buildApp() {
  const app = Fastify();
  app.get('/hello/:name', async (req) => {
    const name = (req.params as { name: string }).name;
    return { message: greet(name) };
  });
  return app;
}
export type AppType = ReturnType<typeof buildApp>;
TS

# Minimal index that only listens in normal runs
cat > apps/api/src/index.ts <<'TS'
import { buildApp } from './app';

const app = buildApp();
const port = Number(process.env.PORT ?? 3001);

app.listen({ port, host: '0.0.0.0' }).then(() => {
  console.log(`api listening on http://localhost:${port}`);
});
TS

mkdir -p apps/api/test
cat > apps/api/test/app.test.ts <<'TS'
import { describe, it, expect } from 'vitest';
import { buildApp } from '../src/app';

describe('api /hello/:name', () => {
  it('returns a greeting', async () => {
    const app = buildApp();
    const res = await app.inject({ method: 'GET', url: '/hello/Ada' });
    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual({ message: 'hello, Ada!' });
  });
});
TS

cat > apps/api/vitest.config.ts <<'TS'
import { defineConfig } from 'vitest/config';
export default defineConfig({
  test: {
    environment: 'node',
    include: ['test/**/*.test.ts'],
    coverage: {
      provider: 'v8',
      reports: ['text', 'lcov'],
    },
  },
});
TS

# add test scripts
node - <<'NODE'
const fs=require('fs');
const f='apps/api/package.json';
const pkg=JSON.parse(fs.readFileSync(f,'utf8'));
pkg.scripts ||= {};
pkg.scripts.test = "vitest run";
pkg.scripts['test:watch'] = "vitest";
pkg.scripts['test:coverage'] = "vitest run --coverage";
fs.writeFileSync(f, JSON.stringify(pkg,null,2));
console.log("✓ api: scripts updated");
NODE

# ────────────────────────────────────────────────────────────────────────────────
# Web app tests (apps/web) — React Testing Library + JSDOM
# ────────────────────────────────────────────────────────────────────────────────
pnpm -C apps/web add -D vitest @vitest/coverage-v8 @types/node jsdom @testing-library/react @testing-library/jest-dom >/dev/null

# Ensure a simple page exists
mkdir -p apps/web/src/app
if [ ! -f apps/web/src/app/page.tsx ]; then
cat > apps/web/src/app/page.tsx <<'TSX'
import { greet } from '@unfinished-world/shared';
export default function Home() {
  return (
    <main style={{ padding: 24 }}>
      <h1>Web</h1>
      <p>{greet('web')}</p>
    </main>
  );
}
TSX
fi

cat > apps/web/src/app/page.test.tsx <<'TSX'
import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import Home from './page';

describe('web Home page', () => {
  it('renders greeting from shared', () => {
    render(<Home />);
    expect(screen.getByText('hello, web!')).toBeInTheDocument();
  });
});
TSX

cat > apps/web/vitest.setup.ts <<'TS'
import '@testing-library/jest-dom/vitest';
TS

cat > apps/web/vitest.config.ts <<'TS'
import { defineConfig } from 'vitest/config';
export default defineConfig({
  test: {
    environment: 'jsdom',
    setupFiles: ['./vitest.setup.ts'],
    include: ['src/**/*.test.{ts,tsx}'],
    coverage: {
      provider: 'v8',
      reports: ['text', 'lcov'],
    },
  },
});
TS

# add test scripts
node - <<'NODE'
const fs=require('fs');
const f='apps/web/package.json';
const pkg=JSON.parse(fs.readFileSync(f,'utf8'));
pkg.scripts ||= {};
pkg.scripts.test = "vitest run";
pkg.scripts['test:watch'] = "vitest";
pkg.scripts['test:coverage'] = "vitest run --coverage";
fs.writeFileSync(f, JSON.stringify(pkg,null,2));
console.log("✓ web: scripts updated");
NODE

# ────────────────────────────────────────────────────────────────────────────────
# GitHub Actions: add tests to CI
# ────────────────────────────────────────────────────────────────────────────────
cat > .github/workflows/ci.yml <<'YML'
name: CI
on:
  push: { branches: [ main, master ] }
  pull_request: { branches: [ "**" ] }
jobs:
  build:
    runs-on: ubuntu-latest
    permissions: { contents: read, actions: read }
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'pnpm'
      - name: Enable Corepack
        run: corepack enable
      - name: Install
        run: pnpm install --frozen-lockfile
      - name: Lint
        run: pnpm lint
      - name: Typecheck
        run: pnpm typecheck
      - name: Test
        run: pnpm test
      - name: Build
        run: pnpm build
YML

# ────────────────────────────────────────────────────────────────────────────────
# Install + first test run
# ────────────────────────────────────────────────────────────────────────────────
echo "📦 Installing (to ensure new devDeps are wired)..."
pnpm install

echo "▶️ Running tests once..."
pnpm test

echo "✅ Done. Try:"
echo "  • pnpm test            # run all tests"
echo "  • pnpm -C apps/web test:watch"
echo "  • pnpm -C apps/api test:watch"
echo "  • pnpm -C packages/shared test:watch"
echo "  • pnpm test:coverage   # aggregate coverage across packages (via Turbo)"
