import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  workers: 1,
  use: {
    baseURL: 'http://127.0.0.1:1421',
    browserName: 'chromium',
    viewport: { width: 1280, height: 900 },
    screenshot: 'only-on-failure',
  },
  webServer: {
    command: 'npm run dev -- --port 1421',
    url: 'http://127.0.0.1:1421',
    reuseExistingServer: false,
  },
});
