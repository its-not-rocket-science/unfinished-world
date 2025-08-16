#!/usr/bin/env bash
set -euo pipefail

# ────────────────────────────────────────────────────────────────────────────────
# Config — tweak these for future projects
# ────────────────────────────────────────────────────────────────────────────────
ROOT_NAME="unfinished-world"
SCOPE="@unfinished-world"
NODE_MIN="18.18.0"
PNPM_VER="10.14.0"         # Must be an exact version (e.g. 10.14.0)
NEXT_APP_DIR="apps/web"
API_APP_DIR="apps/api"
SHARED_PKG_DIR="packages/shared"

# ────────────────────────────────────────────────────────────────────────────────
# Helpers
# ────────────────────────────────────────────────────────────────────────────────
need() { command -v "$1" >/dev/null 2>&1; }
semver_ge() { # semver_ge A B => 0 if A>=B
  node -e "const [a,b]=process.argv.slice(1);const p=v=>v.split('.').map(Number);const A=p(a),B=p(b);process.exit((A[0]>B[0]||A[0]===B[0]&&(A[1]>B[1]||A[1]===B[1]&&A[2]>=B[2]))?0:1)" "$1" "$2" >/dev/null
}

# ────────────────────────────────────────────────────────────────────────────────
# Preflight checks
# ────────────────────────────────────────────────────────────────────────────────
if ! need node; then echo "❌ Node.js is required (>= ${NODE_MIN})." >&2; exit 1; fi
NODE_VER="$(node -v | sed 's/^v//')"
if ! semver_ge "$NODE_VER" "$NODE_MIN"; then
  echo "❌ Node $NODE_VER found; need >= ${NODE_MIN}." >&2; exit 1
fi

if ! need pnpm; then
  echo "ℹ️ pnpm not found — enabling via Corepack…"
  if need corepack; then corepack enable; else
    echo "❌ Corepack not available. Install pnpm (npm i -g pnpm) and retry." >&2; exit 1
  fi
fi

echo "✅ Using Node v$NODE_VER, pnpm $(pnpm -v)"
if [ "$(pnpm -v)" != "$PNPM_VER" ]; then
  echo "⚠️  Your pnpm is $(pnpm -v), but packageManager will be pinned to pnpm@${PNPM_VER}."
fi

# ────────────────────────────────────────────────────────────────────────────────
# Root workspace
# ────────────────────────────────────────────────────────────────────────────────
mkdir -p "$(dirname "$NEXT_APP_DIR")" "$(dirname "$API_APP_DIR")" "$(dirname "$SHARED_PKG_DIR")" .github/workflows

# Root package.json (overwrites/creates)
cat > package.json <<JSON
{
  "name": "${ROOT_NAME}",
  "private": true,
  "type": "module",
  "packageManager": "pnpm@${PNPM_VER}",
  "scripts": {
    "dev": "turbo run dev --parallel",
    "build": "turbo run build",
    "lint": "turbo run lint",
    "typecheck": "turbo run typecheck",
    "test": "turbo run test -- --coverage",
    "test:coverage": "turbo run test -- --coverage",
    "clean": "turbo run clean",
    "format": "prettier . -w",
    "format:check": "prettier . -c",
    "prepare": "husky",
    "ci": "pnpm lint && pnpm typecheck && pnpm test && pnpm build"
  },
  "engines": { "node": ">=${NODE_MIN}" }
}
JSON

# pnpm workspace + tsconfig base
cat > pnpm-workspace.yaml <<'YAML'
packages:
  - "apps/*"
  - "packages/*"
YAML

cat > tsconfig.base.json <<JSON
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022", "DOM"],
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "resolveJsonModule": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noFallthroughCasesInSwitch": true,
    "baseUrl": ".",
    "paths": {
      "${SCOPE}/shared": ["${SHARED_PKG_DIR}/src/index.ts"],
      "${SCOPE}/shared/*": ["${SHARED_PKG_DIR}/src/*"]
    }
  }
}
JSON

# .gitignore
cat > .gitignore <<'GIT'
node_modules
.pnp.cjs
.pnpm-debug.log
dist
.next
.out
.turbo
.env
.DS_Store
coverage
GIT

# ────────────────────────────────────────────────────────────────────────────────
# Shared package
# ────────────────────────────────────────────────────────────────────────────────
mkdir -p "${SHARED_PKG_DIR}/src"

cat > "${SHARED_PKG_DIR}/package.json" <<JSON
{
  "name": "${SCOPE}/shared",
  "version": "0.0.0",
  "private": false,
  "type": "module",
  "main": "./dist/index.js",
  "types": "./dist/index.d.ts",
  "exports": { ".": { "types": "./dist/index.d.ts", "import": "./dist/index.js" } },
  "scripts": {
    "build": "tsc -p tsconfig.build.json",
    "dev": "tsc -w -p tsconfig.build.json",
    "clean": "rimraf dist",
    "typecheck": "tsc -p tsconfig.build.json --noEmit",
    "lint": "eslint . --ext .ts,.tsx --max-warnings 0",
    "test": "vitest run",
    "test:watch": "vitest",
    "test:coverage": "vitest run --coverage"
  },
  "devDependencies": {
    "rimraf": "^6.0.0",
    "typescript": "^5.6.0",
    "@types/node": "^24.3.0",
    "vitest": "^3.2.4",
    "@vitest/coverage-v8": "^2.1.5"
  }
}
JSON

cat > "${SHARED_PKG_DIR}/tsconfig.build.json" <<'JSON'
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "outDir": "dist",
    "declaration": true,
    "sourceMap": true
  },
  "include": ["src"]
}
JSON

cat > "${SHARED_PKG_DIR}/src/index.ts" <<'TS'
export const greet = (name: string) => `hello, ${name}!`;
TS

mkdir -p "${SHARED_PKG_DIR}/test"
cat > "${SHARED_PKG_DIR}/test/index.test.ts" <<'TS'
import { describe, it, expect } from 'vitest';
import { greet } from '../src';

describe('shared/greet', () => {
  it('says hello', () => {
    expect(greet('web')).toBe('hello, web!');
  });
});
TS

cat > "${SHARED_PKG_DIR}/vitest.config.ts" <<'TS'
import { defineConfig } from 'vitest/config';
export default defineConfig({
  test: {
    environment: 'node',
    include: ['test/**/*.test.ts'],
    coverage: { provider: 'v8', reports: ['text', 'lcov'] }
  }
});
TS

# ────────────────────────────────────────────────────────────────────────────────
# Next.js app
# ────────────────────────────────────────────────────────────────────────────────
if [ ! -d "$NEXT_APP_DIR" ]; then
  pnpm dlx create-next-app@latest "$NEXT_APP_DIR" \
    --ts --eslint --src-dir --app --use-pnpm \
    --import-alias "@/*" --turbopack --yes
fi

# Overwrite Next tsconfig to extend repo base
cat > "${NEXT_APP_DIR}/tsconfig.json" <<'JSON'
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "baseUrl": ".",
    "paths": { "@/*": ["./src/*"] },
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }]
  }
}
JSON

# Ensure ESM + scripts + deps
node - <<NODE
const fs=require('fs');const f='${NEXT_APP_DIR}/package.json';
const p=JSON.parse(fs.readFileSync(f,'utf8'));
p.type='module';
p.scripts=p.scripts||{};
p.scripts.dev='next dev';
p.scripts.build='next build';
p.scripts.start='next start';
p.scripts.lint='eslint . --ext .ts,.tsx --max-warnings 0';
p.scripts.typecheck='tsc --noEmit';
p.scripts.clean=p.scripts.clean||'rimraf .next';
fs.writeFileSync(f, JSON.stringify(p,null,2));
NODE

mkdir -p "${NEXT_APP_DIR}/src/app"
cat > "${NEXT_APP_DIR}/src/app/page.tsx" <<TSX
import { greet } from '${SCOPE}/shared';

export default function Home() {
  return (
    <main style={{ padding: 24 }}>
      <h1>Web</h1>
      <p>{greet('web')}</p>
    </main>
  );
}
TSX

# Web tests + config (Vitest + RTL + JSDOM, auto JSX runtime)
pnpm -C "$NEXT_APP_DIR" add -D vitest @vitest/coverage-v8 @types/node jsdom @testing-library/react @testing-library/jest-dom >/dev/null

cat > "${NEXT_APP_DIR}/src/app/page.test.tsx" <<'TSX'
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

cat > "${NEXT_APP_DIR}/vitest.setup.ts" <<'TS'
import '@testing-library/jest-dom/vitest';
TS

cat > "${NEXT_APP_DIR}/vitest.config.ts" <<'TS'
import { defineConfig } from 'vitest/config';
export default defineConfig({
  test: {
    environment: 'jsdom',
    setupFiles: ['./vitest.setup.ts'],
    include: ['src/**/*.test.{ts,tsx}'],
    coverage: { provider: 'v8', reports: ['text', 'lcov'] }
  },
  esbuild: {
    jsx: 'automatic',
    jsxImportSource: 'react'
  }
});
TS

# Ensure web depends on shared
pnpm -C "$NEXT_APP_DIR" add "${SCOPE}/shared@workspace:*" >/dev/null || true

# ────────────────────────────────────────────────────────────────────────────────
# API app (Fastify + TS) + tests
# ────────────────────────────────────────────────────────────────────────────────
mkdir -p "${API_APP_DIR}/src" "${API_APP_DIR}/test"

cat > "${API_APP_DIR}/package.json" <<JSON
{
  "name": "api",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc -p tsconfig.build.json",
    "start": "node dist/index.js",
    "clean": "rimraf dist",
    "typecheck": "tsc -p tsconfig.build.json --noEmit",
    "lint": "eslint . --ext .ts --max-warnings 0",
    "test": "vitest run",
    "test:watch": "vitest",
    "test:coverage": "vitest run --coverage"
  },
  "dependencies": {
    "fastify": "^4.28.1",
    "${SCOPE}/shared": "workspace:*"
  },
  "devDependencies": {
    "tsx": "^4.20.4",
    "typescript": "^5.6.0",
    "rimraf": "^6.0.0",
    "@types/node": "^24.3.0",
    "vitest": "^3.2.4",
    "@vitest/coverage-v8": "^2.1.5"
  }
}
JSON

cat > "${API_APP_DIR}/tsconfig.build.json" <<'JSON'
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "outDir": "dist",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "sourceMap": true
  },
  "include": ["src"]
}
JSON

cat > "${API_APP_DIR}/src/app.ts" <<'TS'
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

cat > "${API_APP_DIR}/src/index.ts" <<'TS'
import { buildApp } from './app';

const app = buildApp();
const port = Number(process.env.PORT ?? 3001);

app.listen({ port, host: '0.0.0.0' }).then(() => {
  console.log(`api listening on http://localhost:${port}`);
});
TS

cat > "${API_APP_DIR}/test/app.test.ts" <<'TS'
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

cat > "${API_APP_DIR}/vitest.config.ts" <<'TS'
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

# ────────────────────────────────────────────────────────────────────────────────
# Turborepo (Turbo v2 syntax: tasks)
# ────────────────────────────────────────────────────────────────────────────────
pnpm add -D -w turbo >/dev/null
cat > turbo.json <<'JSON'
{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "dev": { "cache": false, "persistent": true },
    "build": { "dependsOn": ["^build"], "outputs": ["dist/**", ".next/**"] },
    "typecheck": { "dependsOn": ["^typecheck"] },
    "lint": { "dependsOn": ["^lint"] },
    "test": { "dependsOn": ["^test"], "outputs": ["coverage/**"] },
    "clean": { "cache": false }
  }
}
JSON

# ────────────────────────────────────────────────────────────────────────────────
# ESLint + Prettier (root + web)
# ────────────────────────────────────────────────────────────────────────────────
pnpm add -D -w eslint prettier @typescript-eslint/parser @typescript-eslint/eslint-plugin eslint-config-prettier eslint-plugin-react eslint-plugin-react-hooks husky lint-staged >/dev/null
pnpm -C "$NEXT_APP_DIR" add -D eslint-config-next typescript >/dev/null
pnpm -C "$NEXT_APP_DIR" add next react react-dom >/dev/null
pnpm -C "$API_APP_DIR" add fastify >/dev/null

cat > .eslintrc.cjs <<'CJS'
/** @type {import('eslint').Linter.Config} */
module.exports = {
  root: true,
  ignorePatterns: ["node_modules/", "dist/", ".next/", "coverage/", ".turbo/"],
  parser: "@typescript-eslint/parser",
  plugins: ["@typescript-eslint"],
  extends: ["eslint:recommended", "plugin:@typescript-eslint/recommended", "prettier"],
  overrides: [
    { files: ["apps/web/**/*.{ts,tsx}"], extends: ["next/core-web-vitals", "plugin:@typescript-eslint/recommended", "prettier"] },
    { files: ["apps/api/**/*.ts"], env: { node: true } },
    { files: ["packages/shared/**/*.ts"] }
  ]
};
CJS

cat > .prettierrc <<'JSON'
{ "printWidth": 100, "singleQuote": true, "trailingComma": "all", "semi": true, "arrowParens": "always" }
JSON

cat > .prettierignore <<'TXT'
node_modules
dist
.next
.turbo
coverage
TXT

# ────────────────────────────────────────────────────────────────────────────────
# GitHub Actions CI
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
# Husky v9 + lint-staged (pre-commit)
# ────────────────────────────────────────────────────────────────────────────────
# Ensure package.json has lint-staged config
node - <<'NODE'
const fs=require('fs');const f='package.json';
const pkg=JSON.parse(fs.readFileSync(f,'utf8'));
pkg['lint-staged'] ||= {
  '*.{js,jsx,ts,tsx}': [
    'pnpm exec eslint --fix --cache --max-warnings=0',
    'pnpm exec prettier --write'
  ],
  '*.{json,md,yml,yaml,css,scss,html}': [
    'pnpm exec prettier --write'
  ]
};
fs.writeFileSync(f, JSON.stringify(pkg,null,2));
console.log('✓ package.json: lint-staged config ready');
NODE

echo "📦 Installing workspace deps…"
pnpm install

echo "🐶 Initializing Husky (v9)…"
pnpm exec husky init "pnpm exec lint-staged" >/dev/null
chmod +x .husky/pre-commit || true

# ────────────────────────────────────────────────────────────────────────────────
# First builds & tips
# ────────────────────────────────────────────────────────────────────────────────
echo "🔨 Build shared package…"
pnpm -C "${SHARED_PKG_DIR}" build

echo
echo "✅ Monorepo ready!"
echo
echo "Dev (all):      pnpm dev"
echo "Web only:       pnpm -C ${NEXT_APP_DIR} dev"
echo "API only:       pnpm -C ${API_APP_DIR} dev"
echo "Quality:        pnpm lint | pnpm typecheck | pnpm test | pnpm format"
echo
echo "One-time (pnpm v10) – approve native builds if prompted:"
echo "  pnpm ignored-builds"
echo "  pnpm approve-builds"
echo
echo "If you ever re-create the Next app:"
echo "  pnpm dlx create-next-app@latest ${NEXT_APP_DIR} --ts --eslint --src-dir --app --use-pnpm --import-alias \"@/*\" --turbopack --yes"
