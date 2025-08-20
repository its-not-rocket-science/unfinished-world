import js from '@eslint/js';
import tseslint from 'typescript-eslint';

export default tseslint.config(
  // Ignore build artifacts across the monorepo
  {
    ignores: [
      '**/dist/**',
      '**/.next/**',
      '**/coverage/**',
      '**/node_modules/**',
      '**/pnpm-lock.yaml',
    ],
  },

  // Base JS rules
  js.configs.recommended,

  // TypeScript (fast, non-type-aware)
  ...tseslint.configs.recommended,

  // TS / TSX across repo
  {
    files: ['**/*.ts', '**/*.tsx'],
    languageOptions: {
      sourceType: 'module',
      // If you later want type-aware rules, switch to
      // ...tseslint.configs.recommendedTypeChecked above and set parserOptions.project
    },
    rules: {
      // shared rules here
      // 'no-console': 'warn',
    },
  },

  // Tests: relax a couple of things if you like
  {
    files: ['**/test/**/*.{ts,tsx}', '**/*.test.{ts,tsx}'],
    rules: {
      // examples:
      // '@typescript-eslint/no-explicit-any': 'off',
    },
  },
);
