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
