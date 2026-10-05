import { test, expect } from '@playwright/test';

test('inspects a simulated APK without a device and retains the report across navigation', async ({
  page,
}) => {
  await page.goto('/?demo=empty');
  await page.getByRole('button', { name: 'APK analysis', exact: true }).click();
  await expect(
    page.getByText('Demo mode — simulated APK analysis.'),
  ).toBeVisible();
  await page.getByRole('button', { name: 'Choose APK', exact: true }).click();
  await expect(
    page.getByText('com.example.demo', { exact: true }),
  ).toBeVisible();
  await expect(page.getByText('1.2.0 (12)', { exact: true })).toBeVisible();
  await expect(page.getByText('5.00 MiB', { exact: true })).toBeVisible();
  await expect(
    page.getByText('No maximum declared', { exact: true }),
  ).toBeVisible();
  await expect(
    page.getByRole('heading', { name: 'Signature', exact: true }),
  ).toBeVisible();
  await expect(page.getByLabel('Signature verification status')).toHaveText(
    'Verified · v2',
  );
  await expect(
    page.getByText(
      'Simulated verification result. No real APK signature was checked.',
    ),
  ).toBeVisible();
  await expect(page.getByText('SHA256withRSA', { exact: true })).toBeVisible();
  await expect(page.getByText('Archive contents', { exact: true })).toHaveCount(
    0,
  );
  await page
    .getByRole('button', { name: 'Device overview', exact: true })
    .click();
  await page.getByRole('button', { name: 'APK analysis', exact: true }).click();
  await expect(
    page.getByText('com.example.demo', { exact: true }),
  ).toBeVisible();
});

test('shows an explicit simulated analysis error', async ({ page }) => {
  await page.goto('/?demo=error');
  await page.getByRole('button', { name: 'APK analysis', exact: true }).click();
  await page.getByRole('button', { name: 'Choose APK', exact: true }).click();
  await expect(
    page.getByText('Simulated invalid APK. Choose another file to retry.'),
  ).toBeVisible();
  await expect(page.getByLabel('APK report')).toHaveCount(0);
});
