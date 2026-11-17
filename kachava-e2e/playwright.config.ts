import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  timeout: 90000,
  expect: {
    timeout: 20000,
  },
  fullyParallel: false,
  workers: 1,
  retries: 0,
  reporter: [['list']],
  use: {
    headless: false,
    launchOptions: {
      slowMo: 250,
    },
    trace: 'off',
    screenshot: 'off',
    video: 'off',
    viewport: { width: 1280, height: 860 },
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'], channel: 'chrome' },
    },
  ],
});
