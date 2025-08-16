#!/usr/bin/env bash
set -euo pipefail

# ────────────────────────────────────────────────────────────────────────────────
# Config
# ────────────────────────────────────────────────────────────────────────────────
ROOT_NAME="unfinished-world"
SCOPE="@unfinished-world"
NODE_MIN="18.18.0"

need() { command -v "$1" >/dev/null 2>&1; }
semver_ge() {
  python - "$1" "$2" <<'PY' 2>/dev/null || node -e "
const [a,b]=process.argv.slice(1);
const pa=v=>v.split('.').map(Number);
const [a1,a2,a3]=pa(a),[b1,b2,b3]=pa(b);
process.exit((a1>b1)||(a1===b1&&a2>b2)||(a1===b1&&a2===b2&&a3>=b3)?0:1);
" "$1" "$2" >/dev/null
import sys
p=lambda v:list(map(int,v.split('.')))
a,b=p(sys.argv[1]),p(sys.argv[2])
sys.exit(0 if (a>b or a==b) else 1)
PY
}

# ────────────────────────────────────────────────────────────────────────────────
# Checks
# ────────────────────────────────────────────────────────────────────────────────
if ! need node; then
  echo "❌ Node.js is required (>= ${NODE_MIN})." >&2; exit 1
fi
NODE_VER=$(node -v | sed 's/^v//')
if ! semver_ge "$NODE_VER" "$NODE_MIN"; then
  echo "❌ Node $NODE_VER found; need >= ${NODE_MIN}." >&2; exit 1
fi

if ! need pnpm; then
  echo "ℹ️ pnpm not found — enabling via Corepack…"
  if need corepack; then corepack enable; else
    echo "❌ Corepack not available. Install pnpm (npm i -g pnpm) and retry." >&2; exit 1
  fi
fi

echo "✅ Using Node $(node -v), pnpm $(pnpm -v)"

# ────────────────────────────────────────────────────────────────────────────────
# Root / workspace base
# ────────────────────────────────────────────────────────────────────────────────
mkdir -p apps packages .github/workflows

# Write package.json directly (avoid pnpm init flags)
cat > package.json <<JSON
{
  "name": "${ROOT_NAME}",
  "private": true,
  "packageManager": "pnpm@10",
  "scripts": {
    "dev": "turbo run dev --parallel",
    "build": "turbo run build",
    "lint": "turbo run lint",
    "typecheck": "turbo run typecheck",
    "clean": "turbo run clean",
    "format": "prettier . -w",
    "format:check": "prettier . -c",
    "ci": "pnpm lint && pnpm typecheck && pnpm build"
  },
  "engines": { "node": ">=${NODE_MIN}" }
}
JSON

cat > pnpm-workspace.yaml <<'YAML'
packages:
  - "apps/*"
  - "packages/*"
YAML

cat > tsconfig.base.json <<'JSON'
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
      "@unfinished-world/shared": ["packages/shared/src/index.ts"],
      "@unfinished-world/shared/*": ["packages/shared/src/*"]
    }
  }
}
JSON

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
mkdir -p packages/shared/src
cat > packages/shared/package.json <<JSON
{
  "name": "${SCOPE}/shared",
  "version": "0.0.0",
  "private": false,
  "type": "module",
  "main": "./dist/index.js",
  "types": "./dist/index.d.ts",
  "exports": {
    ".": {
      "types": "./dist/index.d.ts",
      "import": "./dist/index.js"
    }
  },
  "scripts": {
    "build": "tsc -p tsconfig.build.json",
    "dev": "tsc -w -p tsconfig.build.json",
    "clean": "rimraf dist",
    "typecheck": "tsc -p tsconfig.build.json --noEmit",
    "lint": "eslint . --ext .ts,.tsx --max-warnings 0"
  },
  "devDependencies": {
    "typescript": "^5.6.0",
    "rimraf": "^6.0.0"
  }
}
JSON

cat > packages/shared/tsconfig.build.json <<'JSON'
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

cat > packages/shared/src/index.ts <<'TS'
export const greet = (name: string) => `hello, ${name}!`;
TS

# ────────────────────────────────────────────────────────────────────────────────
# Next.js app
# ────────────────────────────────────────────────────────────────────────────────
if [ ! -d apps/web ]; then
  pnpm dlx create-next-app@latest apps/web --ts --eslint --src-dir --app --use-pnpm --import-alias "@/*" --no-tailwind --no-git
fi

cat > apps/web/tsconfig.json <<'JSON'
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

mkdir -p apps/web/src/app
cat > apps/web/src/app/page.tsx <<'TSX'
import { greet } from "@unfinished-world/shared";

export default function Home() {
  return (
    <main style={{ padding: 24 }}>
      <h1>Web</h1>
      <p>{greet("web")}</p>
    </main>
  );
}
TSX

# Ensure reasonable scripts in web pkg
cat > apps/web/package.json <<'JSON'
{
  "name": "web",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "eslint . --ext .ts,.tsx --max-warnings 0",
    "typecheck": "tsc --noEmit",
    "clean": "rimraf .next"
  },
  "dependencies": {},
  "devDependencies": {}
}
JSON

# ────────────────────────────────────────────────────────────────────────────────
# API app
# ────────────────────────────────────────────────────────────────────────────────
mkdir -p apps/api/src
cat > apps/api/package.json <<JSON
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
    "lint": "eslint . --ext .ts --max-warnings 0"
  },
  "dependencies": {
    "fastify": "^4.28.1",
    "@unfinished-world/shared": "workspace:*"
  },
  "devDependencies": {
    "tsx": "^4.19.0",
    "typescript": "^5.6.0",
    "rimraf": "^6.0.0"
  }
}
JSON

cat > apps/api/tsconfig.build.json <<'JSON'
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

cat > apps/api/src/index.ts <<'TS'
import Fastify from "fastify";
import { greet } from "@unfinished-world/shared";

const app = Fastify();

app.get("/hello/:name", async (req, reply) => {
  const name = (req.params as { name: string }).name;
  return { message: greet(name) };
});

const port = Number(process.env.PORT ?? 3001);
app.listen({ port, host: "0.0.0.0" }).then(() => {
  console.log(`api listening on http://localhost:${port}`);
});
TS

# ────────────────────────────────────────────────────────────────────────────────
# Turborepo
# ────────────────────────────────────────────────────────────────────────────────
pnpm add -D -w turbo >/dev/null
cat > turbo.json <<'JSON'
{
  "$schema": "https://turbo.build/schema.json",
  "pipeline": {
    "dev": { "cache": false, "persistent": true },
    "build": { "dependsOn": ["^build"], "outputs": ["dist/**", ".next/**"] },
    "typecheck": { "dependsOn": ["^typecheck"] },
    "lint": { "dependsOn": ["^lint"] },
    "clean": { "cache": false }
  }
}
JSON

# ────────────────────────────────────────────────────────────────────────────────
# ESLint + Prettier
# ────────────────────────────────────────────────────────────────────────────────
pnpm add -D -w eslint prettier @typescript-eslint/parser @typescript-eslint/eslint-plugin eslint-config-prettier eslint-plugin-react eslint-plugin-react-hooks >/dev/null
pnpm -C apps/web add -D eslint-config-next next react react-dom >/dev/null
pnpm -C apps/web add -D typescript >/dev/null

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
      - name: Build
        run: pnpm build
YML

# ────────────────────────────────────────────────────────────────────────────────
# Wire deps + first build
# ────────────────────────────────────────────────────────────────────────────────
pnpm -C apps/web add ${SCOPE}/shared@workspace:* >/dev/null || true

echo "📦 Installing…"
pnpm install

echo "🔨 Building shared package…"
pnpm -C packages/shared build

echo "✅ Setup complete!

Dev:
  pnpm dev
    • runs web (Next) and api (Fastify)

Individually:
  pnpm -C apps/web dev
  pnpm -C apps/api dev

Quality:
  pnpm lint
  pnpm typecheck
  pnpm format
  pnpm format:check

CI:
  • .github/workflows/ci.yml is ready

API test:
  curl http://localhost:3001/hello/world
"

