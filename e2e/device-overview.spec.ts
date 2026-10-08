import { test, expect } from '@playwright/test';

test('shows a rendered screen beside device information and stacks it in narrow windows', async ({
  page,
}, testInfo) => {
  await page.setViewportSize({ width: 1100, height: 760 });
  await page.goto('/?demo=devices');
  const preview = page.getByRole('region', {
    name: 'Simulated screen preview',
  });
  const information = page.getByRole('region', {
    name: 'Simulated Android information',
  });
  const image = preview.getByRole('img', { name: 'Screen capture of Pixel 9' });
  await expect(image).toBeVisible();
  const save = preview.getByRole('button', { name: 'Save preview' });
  await expect(save).toBeEnabled();
  await save.click();
  await expect(preview.getByRole('status')).toHaveText(
    'Simulated save. No file was created.',
  );
  await expect
    .poll(() =>
      image.evaluate((element) => (element as HTMLImageElement).naturalWidth),
    )
    .toBe(360);
  const left = await information.boundingBox();
  const right = await preview.boundingBox();
  expect(right!.x).toBeGreaterThanOrEqual(left!.x + left!.width);
  const refresh = await preview
    .getByRole('button', { name: 'Refresh preview' })
    .boundingBox();
  expect(refresh!.y + refresh!.height).toBeLessThan(725);
  await page.screenshot({
    path: testInfo.outputPath('device-overview-initial.png'),
  });
  await preview.getByRole('button', { name: 'Refresh preview' }).click();
  await expect(image).toBeVisible();
  await page.setViewportSize({ width: 800, height: 900 });
  const details = await page
    .getByRole('region', { name: 'Device connection details' })
    .boundingBox();
  const stacked = await preview.boundingBox();
  expect(stacked!.y).toBeGreaterThanOrEqual(details!.y + details!.height);
  expect(await page.evaluate(() => document.documentElement.scrollWidth)).toBe(
    800,
  );
});
