import { expect, test } from '@playwright/test';

test('scrolls within wrapped unbroken messages taller than the viewport', async ({
  page,
}) => {
  await page.clock.setFixedTime(new Date('2026-10-13T12:00:00Z'));
  await page.goto('/?demo=devices&logcat=long');
  await page.getByRole('button', { name: 'Logcat', exact: true }).click();
  const output = page.getByLabel('Logcat output');
  await expect(output).toContainText('payload=');
  await page.getByLabel('Soft wrap').check();
  await page.getByRole('button', { name: 'First line', exact: true }).click();
  const first = output.locator('[data-entry-id="0"]');
  await expect(first).toBeInViewport();
  await expect
    .poll(() => first.evaluate((element) => element.clientHeight))
    .toBeGreaterThan((await output.boundingBox())!.height);
  await expect
    .poll(() =>
      output.evaluate((element) => element.scrollWidth <= element.clientWidth),
    )
    .toBe(true);
  await output.hover();
  await page.mouse.wheel(0, 120);
  await expect
    .poll(() => output.evaluate((element) => element.scrollTop))
    .toBeGreaterThan(50);
  await expect(first).toBeInViewport();
  await page.getByRole('button', { name: 'First line', exact: true }).click();
  await expect
    .poll(() => output.evaluate((element) => element.scrollTop))
    .toBe(0);
  await output.hover();
  await page.mouse.wheel(0, 120);
  await expect
    .poll(() => output.evaluate((element) => element.scrollTop))
    .toBeGreaterThan(50);
  await output.focus();
  await page.keyboard.press('Home');
  await expect
    .poll(() => output.evaluate((element) => element.scrollTop))
    .toBe(0);
  await page.keyboard.press('End');
  await expect
    .poll(() =>
      output.evaluate((element) =>
        Math.abs(
          element.scrollHeight - element.clientHeight - element.scrollTop,
        ),
      ),
    )
    .toBeLessThan(2);
});

test('wraps logs without overlap and preserves browsing, search and live following', async ({
  page,
}) => {
  await page.goto('/?demo=devices&logcat=large');
  await page.getByRole('button', { name: 'Logcat', exact: true }).click();
  const output = page.getByLabel('Logcat output');
  await expect(output).toContainText('#20000');
  // A narrow viewport forces the same layout as long messages in a wide window.
  await output.evaluate((element) => {
    element.style.width = '320px';
  });
  await page.getByLabel('Soft wrap').check();
  await expect(page.getByLabel('Follow live')).toBeChecked();
  await expect
    .poll(() =>
      output.evaluate((element) => element.scrollWidth <= element.clientWidth),
    )
    .toBe(true);
  await page.getByRole('button', { name: 'First line', exact: true }).click();
  const first = output.locator('[data-entry-id="0"]');
  await expect(first).toBeInViewport();
  await expect
    .poll(() =>
      first.evaluate((element) => element.getBoundingClientRect().height),
    )
    .toBeGreaterThan(20);
  const firstBox = (await first.boundingBox())!;
  const secondBox = (await output
    .locator('[data-entry-id="1"]')
    .boundingBox())!;
  expect(secondBox.y).toBeGreaterThanOrEqual(firstBox.y + firstBox.height);
  await output.hover();
  await page.mouse.wheel(0, 1700);
  await expect(first).not.toBeInViewport();
  await expect(page.getByLabel('Follow live')).not.toBeChecked();
  await page.getByRole('searchbox', { name: 'Search logs' }).fill('#12001');
  await expect(output.locator('.logcat-current')).toBeInViewport();
  await output.evaluate((element) => {
    element.style.width = '240px';
  });
  await expect(output.locator('.logcat-current')).toBeInViewport();
  expect(await output.locator('.logcat-line').count()).toBeLessThanOrEqual(200);
  await page.getByRole('button', { name: 'Latest', exact: true }).click();
  await expect(page.getByLabel('Follow live')).toBeChecked();
  await expect
    .poll(() =>
      output.evaluate((element) =>
        Math.abs(
          element.scrollHeight - element.clientHeight - element.scrollTop,
        ),
      ),
    )
    .toBeLessThan(2);
  await page.getByLabel('Soft wrap').uncheck();
  await expect
    .poll(() =>
      output
        .locator('.logcat-line')
        .first()
        .evaluate((element) => element.getBoundingClientRect().height),
    )
    .toBe(20);
  await expect
    .poll(() =>
      output.evaluate((element) => element.scrollWidth > element.clientWidth),
    )
    .toBe(true);
});

test('completes a package from the shared dropdown and expands repeated logs', async ({
  page,
}) => {
  await page.goto('/?demo=devices&logcat=repeats');
  await page.getByRole('button', { name: 'Logcat', exact: true }).click();
  const output = page.getByLabel('Logcat output');
  await expect(
    output.getByLabel('3 identical consecutive entries').first(),
  ).toHaveText('×3');
  await page.getByLabel('Group repeats').uncheck();
  await expect(output.locator('[data-entry-id="0"]')).toBeVisible();
  await expect(output.locator('[data-entry-id="1"]')).toBeVisible();
  await expect(output.locator('[data-entry-id="2"]')).toBeVisible();
  await expect(
    output.getByLabel('3 identical consecutive entries'),
  ).toHaveCount(0);
  const packages = page.getByRole('combobox', {
    name: 'Package name',
    exact: true,
  });
  await packages.click();
  await expect(
    page.getByRole('option', { name: 'All packages', exact: true }),
  ).toBeVisible();
  await packages.fill('example');
  await expect(page.getByRole('option')).toHaveCount(1);
  await packages.press('Enter');
  await expect(packages).toHaveValue('com.example.demo');
  await expect(page.getByRole('listbox')).toHaveCount(0);
  await page
    .getByRole('button', { name: 'Apply package', exact: true })
    .click();
  await expect(output).toContainText('#1');
});

test('browses and searches an entire large history with a bounded DOM', async ({
  page,
}) => {
  await page.goto('/?demo=devices&logcat=large');
  await page.getByRole('button', { name: 'Logcat', exact: true }).click();
  const output = page.getByLabel('Logcat output');
  await expect(output).toContainText('#20000');
  expect(await output.locator('.logcat-line').count()).toBeLessThan(100);
  await page.getByRole('button', { name: 'First line', exact: true }).click();
  await expect(output.locator('[data-entry-id="0"]')).toBeInViewport();
  await output.focus();
  await page.keyboard.press('End');
  await expect(output).toContainText('#20000');
  await page.getByRole('searchbox', { name: 'Search logs' }).fill('#12001');
  await expect(output.locator('.logcat-current')).toContainText('#12001');
  await expect(output.locator('.logcat-current')).toBeInViewport();
  expect(await output.locator('.logcat-line').count()).toBeLessThan(100);
  await page
    .getByRole('button', { name: 'Previous match', exact: true })
    .click();
  await expect(output.locator('.logcat-current')).toBeInViewport();
  await output.hover();
  await page.mouse.wheel(0, -100);
  await expect(page.getByLabel('Follow live')).not.toBeChecked();
  await page.getByRole('button', { name: 'Latest', exact: true }).click();
  await expect(page.getByLabel('Follow live')).toBeChecked();
  await expect(output).toContainText('#20000');
});

test('streams demo logs and navigates highlighted results while retaining context', async ({
  page,
}) => {
  await page.goto('/?demo=devices');
  await page.getByRole('button', { name: 'Logcat', exact: true }).click();
  await expect(
    page.getByRole('heading', { name: 'Logcat', exact: true }),
  ).toBeVisible();
  const output = page.getByLabel('Logcat output');
  await expect(output).toContainText('Simulated network error');
  await expect(output).toContainText('Simulated activity update');
  await page
    .getByRole('searchbox', { name: 'Search logs' })
    .fill('network error');
  await expect(output.locator('.logcat-current')).toBeInViewport();
  await expect(output.locator('mark').first()).toHaveText('network error');
  await expect(page.getByLabel('Follow live')).not.toBeChecked();
  await expect(output).toContainText('Simulated activity update');
  await page.getByRole('combobox', { name: 'Minimum level' }).click();
  await page.getByRole('option', { name: 'Error', exact: true }).click();
  await expect(output).not.toContainText('Simulated activity update');
  await page
    .getByLabel('Package name', { exact: true })
    .fill('com.example.demo');
  await page
    .getByRole('option', { name: 'com.example.demo', exact: true })
    .click();
  await page
    .getByRole('button', { name: 'Apply package', exact: true })
    .click();
  await expect(output).toContainText('#1');
  await page
    .getByRole('button', { name: 'Clear device logs', exact: true })
    .click();
  await expect(output).toContainText('#1');
  await page
    .getByRole('button', { name: 'Device overview', exact: true })
    .click();
  await page.getByRole('button', { name: 'Logcat', exact: true }).click();
  await expect(output).toContainText('#1');
});
