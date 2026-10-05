import js from '@eslint/js';
import prettier from 'eslint-config-prettier';
import vue from 'eslint-plugin-vue';
import globals from 'globals';
import ts from 'typescript-eslint';

export default ts.config(
  {
    ignores: [
      'dist/**',
      'coverage/**',
      'playwright-report/**',
      'test-results/**',
      'src-tauri/target/**',
      'src-tauri/gen/**',
      'src-tauri/Sparkle.framework/**',
      'src-tauri/sparkle-tools/**',
    ],
  },
  js.configs.recommended,
  ...ts.configs.recommended,
  ...vue.configs['flat/recommended'],
  {
    files: ['**/*.{ts,vue}'],
    languageOptions: {
      globals: globals.browser,
      parserOptions: { parser: ts.parser },
    },
  },
  prettier,
  {
    files: ['scripts/*.mjs'],
    languageOptions: { globals: globals.node },
  },
);
