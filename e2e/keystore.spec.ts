import { expect, test } from '@playwright/test';

test('creates a simulated keystore without a device and preserves the form across navigation', async ({
  page,
  context,
}) => {
  await context.grantPermissions(['clipboard-read', 'clipboard-write']);
  await page.goto('/?demo=empty');
  const navigation = page.getByRole('navigation', { name: 'Workspace' });
  await navigation.getByRole('button', { name: 'Generate keystore' }).click();
  await expect(
    page.getByRole('heading', { name: 'Generate keystore' }),
  ).toBeVisible();
  await page.getByRole('button', { name: 'Browse…' }).click();
  await page
    .getByRole('button', { name: 'Generate keystore password', exact: true })
    .click();
  const password = await page
    .getByLabel('Keystore password', { exact: true })
    .inputValue();
  expect(password).toHaveLength(24);
  await expect(
    page.getByLabel('Confirm password', { exact: true }),
  ).toHaveValue(password);
  await page
    .getByRole('button', { name: 'Show keystore password', exact: true })
    .click();
  await expect(
    page.getByLabel('Keystore password', { exact: true }),
  ).toHaveAttribute('type', 'text');
  await page
    .getByRole('button', { name: 'Hide keystore password', exact: true })
    .click();
  await page
    .getByRole('button', { name: 'Copy keystore password', exact: true })
    .click();
  await expect
    .poll(() => page.evaluate(() => navigator.clipboard.readText()))
    .toBe(password);
  await page
    .getByLabel('Name / Common name (CN)', { exact: true })
    .fill('Demo Signing');
  const format = page.getByRole('combobox', { name: 'Keystore format' });
  await format.focus();
  await format.press('ArrowDown');
  await expect(
    page.getByRole('listbox', { name: 'Keystore format' }),
  ).toBeVisible();
  await format.press('End');
  await format.press('Enter');
  await expect(format).toContainText('PKCS12');
  await expect(page.getByLabel('Save location')).toHaveValue(
    '/demo/upload.p12',
  );
  await page
    .getByRole('main')
    .getByRole('button', { name: 'Generate keystore', exact: true })
    .click();
  await expect(
    page.getByRole('heading', { name: 'Simulated keystore generated' }),
  ).toBeVisible();
  await navigation.getByRole('button', { name: 'Device overview' }).click();
  await navigation.getByRole('button', { name: 'Generate keystore' }).click();
  await expect(
    page.getByRole('heading', { name: 'Simulated keystore generated' }),
  ).toBeVisible();
  await expect(
    page.getByLabel('Keystore password', { exact: true }),
  ).toHaveValue(password);
  await page.setViewportSize({ width: 390, height: 844 });
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= window.innerWidth,
    ),
  ).toBe(true);
});

test('shows inline validation and an explicit simulated write failure', async ({
  page,
}) => {
  await page.goto('/?demo=error');
  await page
    .getByRole('navigation', { name: 'Workspace' })
    .getByRole('button', { name: 'Generate keystore' })
    .click();
  const submit = page
    .getByRole('main')
    .getByRole('button', { name: 'Generate keystore', exact: true });
  await submit.click();
  await expect(page.getByLabel('Save location')).toHaveAttribute(
    'aria-invalid',
    'true',
  );
  await page.getByRole('button', { name: 'Browse…' }).click();
  await page
    .getByRole('button', { name: 'Generate keystore password', exact: true })
    .click();
  await page
    .getByLabel('Name / Common name (CN)', { exact: true })
    .fill('Demo Signing');
  await submit.click();
  await expect(page.getByRole('main').getByRole('alert')).toContainText(
    'Simulated failure',
  );
  await expect(submit).toBeEnabled();
  await expect(
    page.getByRole('heading', { name: 'Simulated keystore generated' }),
  ).toHaveCount(0);
});
