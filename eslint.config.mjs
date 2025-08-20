import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import next from '@next/eslint-plugin-next';
import reactHooks from 'eslint-plugin-react-hooks';

export default tseslint.config(
  { ignores: ['**/dist/**', '**/.next/**', '**/coverage/**', '**/node_modules/**'] },

  js.configs.recommended,
  ...tseslint.configs.recommended,

  // Global TS/TSX defaults
  {
    files: ['**/*.ts', '**/*.tsx'],
    languageOptions: { sourceType: 'module' },
  },

  // ✅ Next app override
  {
    files: ['apps/web/**/*.{ts,tsx}'],
    plugins: { '@next/next': next, 'react-hooks': reactHooks },
    rules: {
      // Next's Core Web Vitals rules (if the plugin exposes them)
      ...(next.configs['core-web-vitals']?.rules ?? {}),
      // Ensure hooks rules are present (fixes “react-hooks/exhaustive-deps not found”)
      'react-hooks/rules-of-hooks': 'error',
      'react-hooks/exhaustive-deps': 'warn',
    },
  },
);
