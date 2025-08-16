#!/usr/bin/env bash
set -euo pipefail

# Hardcode pnpm version
PINNED_PNPM_VERSION="10.14.0"
echo "✅ packageManager version pinned to pnpm@${PINNED_PNPM_VERSION} - verify with pnpm -v"

# 1) Set packageManager to the exact pinned pnpm version
node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json','utf8'));
pkg.packageManager = 'pnpm@' + '${PINNED_PNPM_VERSION}';
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
console.log('packageManager set to pnpm@${PINNED_PNPM_VERSION}');
"

# 2) Ensure web app deps/scripts (safe to re-run)
if [ -d apps/web ]; then
  # Ensure runtime deps
  pnpm -C apps/web add next react react-dom
  # Ensure dev deps
  pnpm -C apps/web add -D typescript @types/node @types/react @types/react-dom eslint eslint-config-next
  # Ensure scripts
  node -e "
    const fs = require('fs');
    const f = 'apps/web/package.json';
    const p = JSON.parse(fs.readFileSync(f,'utf8'));
    p.scripts = p.scripts || {};
    p.scripts.dev = 'next dev';
    p.scripts.build = 'next build';
    p.scripts.start = 'next start';
    p.scripts.lint = 'eslint . --ext .ts,.tsx --max-warnings 0';
    p.scripts.typecheck = 'tsc --noEmit';
    p.scripts.clean = p.scripts.clean || 'rimraf .next';
    fs.writeFileSync(f, JSON.stringify(p, null, 2));
  "
fi

# 3) Install once to lock everything
pnpm install

echo
echo "✅ packageManager pinned to pnpm@${PINNED_PNPM_VERSION}"
echo
echo "If build scripts are blocked (sharp/esbuild, etc):"
echo "  pnpm ignored-builds"
echo "  pnpm approve-builds"
