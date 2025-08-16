#!/usr/bin/env bash
set -euo pipefail

echo "🐶 Installing Husky + lint-staged…"
pnpm add -D -w husky lint-staged >/dev/null

# Merge scripts + lint-staged config into package.json (idempotent)
node - <<'NODE'
const fs = require('fs');
const f = 'package.json';
const pkg = JSON.parse(fs.readFileSync(f, 'utf8'));

pkg.scripts ||= {};
const prep = pkg.scripts.prepare || '';
if (!/\bhusky\b/.test(prep)) {
  pkg.scripts.prepare = prep ? `${prep} && husky` : 'husky';
}

// Keep/seed format scripts if missing
pkg.scripts.format = pkg.scripts.format || 'prettier . -w';
pkg.scripts['format:check'] = pkg.scripts['format:check'] || 'prettier . -c';

// Seed lint-staged config if not present
pkg['lint-staged'] ||= {
  '*.{js,jsx,ts,tsx}': [
    'pnpm exec eslint --fix --cache --max-warnings=0',
    'pnpm exec prettier --write'
  ],
  '*.{json,md,yml,yaml,css,scss,html}': [
    'pnpm exec prettier --write'
  ]
};

fs.writeFileSync(f, JSON.stringify(pkg, null, 2));
console.log('✓ package.json updated (prepare + lint-staged)');
NODE

# Ensure deps are installed so "husky" binary is available
pnpm install >/dev/null

echo "📂 Initializing Husky (v9) with a pre-commit that runs lint-staged…"
# This creates .husky dir and a pre-commit hook with the given command
pnpm exec husky init "pnpm exec lint-staged" >/dev/null

# Make sure it's executable (helpful on Windows/Git Bash too)
chmod +x .husky/pre-commit || true

echo "✅ Husky pre-commit ready.
Next steps:
  • Make a change, stage it, and commit — lint-staged will run.

(If you want a pre-push gate, create .husky/pre-push with:)
  #!/usr/bin/env sh
  . \"\$(dirname -- \"\$0\")/_/husky.sh\"
  pnpm typecheck && pnpm test

Tip (Windows/Git Bash): if hooks don't run, check:
  git config core.hooksPath    # should NOT point elsewhere
"
