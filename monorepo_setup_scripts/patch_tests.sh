#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Fixing ESM + Turbo test config..."

# 1) Root package: ensure ESM and make tests run with coverage (to match turbo outputs)
node - <<'NODE'
const fs = require('fs');
const f = 'package.json';
const pkg = JSON.parse(fs.readFileSync(f, 'utf8'));
pkg.type = 'module';
pkg.scripts = pkg.scripts || {};
// run tests with coverage so turbo's outputs ['coverage/**'] isn't empty
pkg.scripts.test = 'turbo run test -- --coverage';
pkg.scripts['test:coverage'] = 'turbo run test -- --coverage';
fs.writeFileSync(f, JSON.stringify(pkg, null, 2));
console.log('✓ package.json: set type=module, test with coverage');
NODE

# 2) Web package: ensure ESM to avoid ERR_REQUIRE_ESM from vitest → vite
if [ -f apps/web/package.json ]; then
  node - <<'NODE'
  const fs = require('fs');
  const f = 'apps/web/package.json';
  const pkg = JSON.parse(fs.readFileSync(f, 'utf8'));
  pkg.type = 'module';
  pkg.scripts = pkg.scripts || {};
  pkg.scripts.test = 'vitest run';            // coverage flag will be passed from turbo
  pkg.scripts['test:watch'] = 'vitest';
  pkg.scripts['test:coverage'] = 'vitest run --coverage';
  fs.writeFileSync(f, JSON.stringify(pkg, null, 2));
  console.log('✓ apps/web/package.json: set type=module');
NODE
fi

# 3) (Optional) If you prefer not to always collect coverage, you can instead
#    remove outputs from turbo. Uncomment the block below to do that instead.
#: <<'ALT'
#node - <<'NODE'
#const fs = require('fs');
#const f = 'turbo.json';
#const turbo = JSON.parse(fs.readFileSync(f, 'utf8'));
#turbo.tasks = turbo.tasks || turbo.pipeline || {};
#if (turbo.tasks.test && turbo.tasks.test.outputs) {
#  delete turbo.tasks.test.outputs;
#}
#fs.writeFileSync(f, JSON.stringify(turbo, null, 2));
#console.log('✓ turbo.json: removed test.outputs to silence warnings without coverage');
#NODE
#ALT

echo "📦 Re-install just in case"
pnpm install

echo "▶️ Running tests..."
pnpm test

echo "✅ Done!"
