# MONOREPO_SETUP.md

## Overview

`setup_monorepo.sh` bootstraps a complete **pnpm + Turborepo** monorepo with:

- `apps/web` — **Next.js** (TypeScript, App Router) + **React Testing Library/JSDOM** tests  
- `apps/api` — **Fastify** (TypeScript) + **Vitest** tests (via Fastify `inject`)  
- `packages/shared` — shared **TypeScript** library (built with `tsc`)  
- Workspace-wide **ESLint + Prettier**  
- **Vitest** everywhere with **coverage**  
- **Turbo** (v2 `tasks`) wired for `dev`, `build`, `lint`, `typecheck`, `test`, `clean`  
- **GitHub Actions CI** (install → lint → typecheck → test → build)  
- **Husky v9** pre-commit with **lint-staged**  
- Pinned **pnpm** version via `packageManager` in `package.json`  

The script is **idempotent** — safe to run multiple times.

---

## Configure first

Edit the constants at the **top** of `setup_monorepo.sh` before running:

```bash
ROOT_NAME="unfinished-world"        # root package name
SCOPE="@unfinished-world"           # npm scope for the shared package
NODE_MIN="18.18.0"                  # minimum Node version
PNPM_VER="10.14.0"                  # exact pnpm version to pin in package.json
NEXT_APP_DIR="apps/web"             # Next.js app directory
API_APP_DIR="apps/api"              # API app directory
SHARED_PKG_DIR="packages/shared"    # shared lib directory
```

---

## Prerequisites

- Node.js ≥ `NODE_MIN`  
- pnpm available (`corepack enable` is fine)

> With pnpm v10+, native dependency **build scripts are blocked** by default (e.g. `sharp`, `esbuild`). Approve once and commit:
>
> ```bash
> pnpm ignored-builds
> pnpm approve-builds
> ```

---

## Run

```bash
chmod +x setup_monorepo.sh
./setup_monorepo.sh
```

### What gets created

```
apps/
  api/
    src/app.ts
    src/index.ts
    test/app.test.ts
    tsconfig.build.json
    vitest.config.ts
    package.json
  web/
    src/app/page.tsx
    src/app/page.test.tsx
    vitest.setup.ts
    vitest.config.ts
    tsconfig.json
    package.json
packages/
  shared/
    src/index.ts
    test/index.test.ts
    tsconfig.build.json
    vitest.config.ts
turbo.json
pnpm-workspace.yaml
tsconfig.base.json
.eslintrc.cjs
.prettierrc
.github/workflows/ci.yml
.husky/pre-commit
```

---

## Common commands

```bash
# Dev (all apps)
pnpm dev

# Individual dev
pnpm -C apps/web dev
pnpm -C apps/api dev

# Quality
pnpm lint
pnpm typecheck
pnpm test        # runs Vitest with coverage across packages
pnpm build
pnpm clean

# Formatting
pnpm format
pnpm format:check
```

---

## Stage-by-stage setup (optional)

If you prefer to assemble the monorepo gradually, run these **legacy scripts in order**:

1. **`setup.sh`**  
   Base pnpm workspace: creates `apps/web`, `apps/api`, `packages/shared`, root scripts, `pnpm-workspace.yaml`, `tsconfig.base.json`, ESLint/Prettier, Turbo, CI.

2. **`patch_setup.sh`**  
   Pins `packageManager` to a specific **pnpm** version (e.g. `10.14.0`), makes Next scaffolding non-interactive, and normalizes the web app’s scripts/deps.

3. **`add_tests.sh`**  
   Adds **Vitest** to web/api/shared with sample tests & coverage, adds Turbo **`tasks.test`**, updates root `test` scripts, and wires CI to run tests.

4. **`patch_turbo.sh`**  
   Updates Turbo config to v2 by switching `pipeline` → **`tasks`** to avoid config errors.

5. **`patch_tests.sh`**  
   Sets root `"type": "module"` and ensures `pnpm test` passes `--coverage` (to match Turbo’s `outputs: ["coverage/**"]`).

6. **`patch_web_tests.sh`**  
   Forces **automatic JSX runtime** in `apps/web/vitest.config.ts` and sets up JSDOM/RTL so TSX tests don’t need `import React`.

7. **`add_husky.sh`**  
   Adds **Husky v9** pre-commit with **lint-staged**:  
   - `"prepare": "husky"` in root `package.json`  
   - `.husky/pre-commit` runs `pnpm exec lint-staged`  
   - root `lint-staged` config (ESLint fix + Prettier on staged files)

> The single **`setup_monorepo.sh`** performs all the above in one go (with the configurable constants).

---

## Notes & tips

- **Approving native builds (pnpm v10+)**  
  Run `pnpm ignored-builds` then `pnpm approve-builds`; commit any changes (lockfile).

- **Windows/Git Bash**  
  Hooks are created executable; if they don’t run, check:
  ```bash
  git config core.hooksPath    # should NOT point elsewhere
  ```

- **CI**  
  `.github/workflows/ci.yml` runs install → lint → typecheck → test → build on pushes/PRs.

- **Extending**  
  Want Playwright e2e, Dockerfiles, env templates, or a Husky **pre-push** hook (`pnpm typecheck && pnpm test`)? Add them on top—this structure is ready for it.
