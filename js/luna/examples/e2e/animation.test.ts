import { test, expect } from '@playwright/test';

test('easing selection, scrubbing and native playback controls', async ({ page }, testInfo) => {
  await page.goto('/animation.html');
  await expect(page.getByRole('heading', { name: 'Motion, by Luna.' })).toBeVisible();
  await page.getByRole('combobox', { name: 'Easing', exact: true }).selectOption('cubicIn');
  await page.getByLabel('再生位置').fill('500');
  await expect(page.getByTestId('progress')).toHaveText('50%');
  const travel = await page.getByTestId('traveler').evaluate(el => {
    const matrix = new DOMMatrix(getComputedStyle(el).transform);
    return matrix.m41 / (el.parentElement!.clientWidth - 32);
  });
  expect(travel).toBeCloseTo(0.125, 2);
  await page.getByRole('button', { name: '再生', exact: true }).click();
  await expect(page.getByTestId('play-state')).toHaveText('running');
  await page.getByRole('button', { name: '一時停止' }).click();
  await expect(page.getByTestId('play-state')).toHaveText('paused');
  await page.getByRole('button', { name: '逆再生' }).click();
  await expect(page.getByTestId('direction')).toHaveText('← Reverse');
  await page.getByRole('button', { name: 'リセット' }).click();
  await expect(page.getByTestId('progress')).toHaveText('0%');
  await page.screenshot({ path: testInfo.outputPath('preview.png'), fullPage: true });
});

test('FLIP reorders existing elements and keeps rapid interactions usable', async ({ page }) => {
  const errors: string[] = [];
  page.on('pageerror', error => errors.push(error.message));
  await page.goto('/animation.html');
  const cards = page.getByTestId('flip-card');
  await expect(cards).toHaveCount(6);
  await expect(cards.first()).toContainText('01');
  await page.getByRole('button', { name: '順番を反転' }).click();
  await expect(cards.first()).toContainText('06');
  await page.getByRole('button', { name: 'シャッフル' }).click();
  await page.getByRole('button', { name: '順番を反転' }).click();
  await expect(cards).toHaveCount(6);
  expect(errors).toEqual([]);
});

test('mobile layout and reduced-motion preference', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await page.goto('/animation.html');
  await expect(page.getByTestId('motion-preference')).toContainText('reduce');
  await expect(page.getByRole('button', { name: '再生', exact: true })).toBeVisible();
  expect(await page.evaluate(() => document.documentElement.scrollWidth)).toBeLessThanOrEqual(390);
  await page.getByRole('button', { name: '再生', exact: true }).click();
  await expect(page.getByTestId('play-state')).toHaveText('finished');
});
