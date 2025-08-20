import js from '@eslint/js';
import tseslint from 'typescript-eslint';

export default tseslint.config(
  // global ignores for this package
  {
    ignores: ['dist/**', 'coverage/**', 'node_modules/**'],
  },

  // JS base
  js.configs.recommended,

  // TypeScript (non-type-aware is fast & simple)
  ...tseslint.configs.recommended,

  // If you want type-aware rules, uncomment the block below instead of the line above:
  // ...tseslint.configs.recommendedTypeChecked,
  // {
  //   languageOptions: {
  //     parserOptions: {
  //       project: ['./tsconfig.build.json', './tsconfig.json'],
  //       tsconfigRootDir: import.meta.dirname,
  //     },
  //   },
  // },

  {
    files: ['**/*.ts'],
    languageOptions: {
      // keep TS in module mode like your package
      sourceType: 'module',
    },
    rules: {
      // your custom rules here
      // 'no-console': 'warn',
    },
  },
);
