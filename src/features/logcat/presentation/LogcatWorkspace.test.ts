import { flushPromises, mount } from '@vue/test-utils';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { reactive, effectScope } from 'vue';
import LogcatWorkspace from './LogcatWorkspace.vue';
import { useLogcat } from './useLogcat';
import { createDemoLogcatService } from '../infrastructure/demoLogcatService';
import type { LogPage, LogSearchResult, LogSnapshot } from '../domain/logcat';
import {
  MAX_SCROLL_HEIGHT,
  offsetToScroll,
  scrollGeometry,
  scrollToOffset,
} from './virtualLogcat';

function deferred<T>() {
  let resolve!: (value: T) => void;
  const promise = new Promise<T>((yes) => {
    resolve = yes;
  });
  return { promise, resolve };
}
async function settle(ms = 40) {
  await flushPromises();
  await vi.advanceTimersByTimeAsync(ms);
  await flushPromises();
}
beforeEach(() => vi.useFakeTimers());
afterEach(() => {
  vi.useRealTimers();
  vi.restoreAllMocks();
});

describe('Disk-backed Logcat workspace', () => {
  it('increments a repeated group and restores every original line when grouping is disabled', async () => {
    const service = createDemoLogcatService(false, 1, 3);
    const wrapper = mount(LogcatWorkspace, {
      props: { deviceId: 'phone', adbConnected: true, service },
    });
    await settle();
    expect(wrapper.findAll('.logcat-line')).toHaveLength(1);
    await settle(450);
    expect(
      wrapper.get('[aria-label="2 identical consecutive entries"]').text(),
    ).toBe('×2');
    await settle(450);
    expect(
      wrapper.get('[aria-label="3 identical consecutive entries"]').text(),
    ).toBe('×3');
    const grouping = wrapper
      .findAll('label')
      .find((label) => label.text().includes('Group repeats'))!;
    await grouping.get('input').setValue(false);
    await settle();
    expect(wrapper.findAll('.logcat-line')).toHaveLength(3);
    expect(
      wrapper.find('[aria-label="3 identical consecutive entries"]').exists(),
    ).toBe(false);
    wrapper.unmount();
  });
  it('renders only a viewport and can return to the first of 20,000 lines', async () => {
    const service = createDemoLogcatService(false, 20000);
    const page = vi.spyOn(service, 'page');
    const stop = vi.spyOn(service, 'stop');
    const wrapper = mount(LogcatWorkspace, {
      props: { deviceId: 'phone', adbConnected: true, service },
    });
    await settle();
    expect(wrapper.text()).toContain('20000 lines captured');
    expect(wrapper.findAll('.logcat-line').length).toBeLessThan(100);
    expect(wrapper.find('.logcat-line[data-entry-id="19999"]').exists()).toBe(
      true,
    );
    await wrapper
      .findAll('button')
      .find((button) => button.text() === 'First line')!
      .trigger('click');
    await settle();
    expect(page).toHaveBeenLastCalledWith(1, 'V', 0, true);
    expect(wrapper.find('.logcat-line[data-entry-id="0"]').exists()).toBe(true);
    expect(wrapper.findAll('.logcat-line').length).toBeLessThan(100);
    expect(
      wrapper.get<HTMLInputElement>('input[type="checkbox"]').element.checked,
    ).toBe(false);
    await wrapper
      .get('[aria-label="Logcat output"]')
      .trigger('keydown', { key: 'End' });
    await settle();
    expect(wrapper.find('.logcat-line[data-entry-id="19999"]').exists()).toBe(
      true,
    );
    wrapper.unmount();
    await flushPromises();
    expect(stop).toHaveBeenCalledWith(1);
  });

  it('searches outside the rendered viewport, wraps backwards and keeps literal context', async () => {
    const service = createDemoLogcatService(false, 20000);
    const wrapper = mount(LogcatWorkspace, {
      props: { deviceId: 'phone', adbConnected: true, service },
    });
    await settle();
    await wrapper.get('#logcat-search').setValue('#12001');
    await settle(250);
    expect(wrapper.get('.logcat-current').text()).toContain('#12001');
    expect(wrapper.get('[role="status"]').text()).toContain(
      'Match at line 12001 of 20000',
    );
    expect(wrapper.findAll('.logcat-line').length).toBeGreaterThan(1);
    await wrapper.get('[aria-label="Previous match"]').trigger('click');
    await settle(100);
    expect(wrapper.get('.logcat-current').text()).toContain('#12001');
    await wrapper.get('#logcat-level').trigger('click');
    await wrapper
      .findAll('[role="option"]')
      .find((option) => option.text() === 'Error')!
      .trigger('click');
    await settle(250);
    expect(wrapper.get('.logcat-current').text()).toContain('#12001');
    expect(wrapper.get('[role="status"]').text()).toContain(
      'Match at line 2401',
    );
    expect(wrapper.get('[aria-label="Logcat output"]').text()).not.toContain(
      'activity update',
    );
    wrapper.unmount();
  });

  it('applies packages and pauses before clearing while retaining browsable history if clear fails', async () => {
    const service = createDemoLogcatService(false, 10000);
    const start = vi.spyOn(service, 'start');
    const pause = vi.spyOn(service, 'pause');
    const clear = vi.spyOn(service, 'clear');
    const wrapper = mount(LogcatWorkspace, {
      props: { deviceId: 'phone', adbConnected: true, service },
    });
    await settle();
    await wrapper.get('#logcat-package').setValue('com.example.demo');
    await wrapper
      .findAll('[role="option"]')
      .find((option) => option.text() === 'com.example.demo')!
      .trigger('click');
    await wrapper.get('form').trigger('submit');
    await settle();
    expect(start).toHaveBeenLastCalledWith('phone', 'com.example.demo');
    clear.mockRejectedValueOnce(new Error('Permission denied'));
    await wrapper
      .findAll('button')
      .find((button) => button.text() === 'Clear device logs')!
      .trigger('click');
    await settle();
    expect(wrapper.get('[role="alert"]').text()).toBe('Permission denied');
    expect(pause.mock.invocationCallOrder.at(-1)!).toBeLessThan(
      clear.mock.invocationCallOrder[0]!,
    );
    await wrapper
      .findAll('button')
      .find((button) => button.text() === 'First line')!
      .trigger('click');
    await settle();
    expect(wrapper.find('.logcat-line[data-entry-id="0"]').exists()).toBe(true);
    wrapper.unmount();
  });

  it('discards obsolete pages and searches after changing the device', async () => {
    const service = createDemoLogcatService(false, 10000);
    const pendingPage = deferred<LogPage>();
    const pendingSearch = deferred<LogSearchResult>();
    const scope = effectScope();
    const props = reactive({ deviceId: 'a', adbConnected: true, service });
    const logs = scope.run(() => useLogcat(props))!;
    await settle();
    vi.spyOn(service, 'page').mockReturnValueOnce(pendingPage.promise);
    logs.follow.value = false;
    logs.offset.value = 100;
    await settle();
    vi.spyOn(service, 'search').mockReturnValueOnce(pendingSearch.promise);
    logs.query.value = 'old phone';
    await settle(200);
    props.deviceId = 'b';
    await settle();
    pendingPage.resolve({
      start: 0,
      entries: [{ id: 0, text: 'OBSOLETE', level: 'I', repeatCount: 1 }],
    });
    pendingSearch.resolve({ position: 99, next: null });
    await settle();
    expect(
      logs.page.value.entries.some((entry) => entry.text === 'OBSOLETE'),
    ).toBe(false);
    expect(logs.match.value).toBeNull();
    scope.stop();
  });

  it('retains history when capture stops with a disk error and disposes a late start', async () => {
    const service = createDemoLogcatService(false, 10000);
    const snapshot: LogSnapshot = {
      counts: [10000, 10000, 6000, 2000, 2000, 0],
      groupedCounts: [10000, 10000, 6000, 2000, 2000, 0],
      error: { code: 'save_failed', message: 'Disk full' },
    };
    vi.spyOn(service, 'read').mockResolvedValue(snapshot);
    const scope = effectScope();
    const logs = scope.run(() =>
      useLogcat(reactive({ deviceId: 'a', adbConnected: true, service })),
    )!;
    await settle();
    expect(logs.status.value).toBe('error');
    expect(logs.error.value).toBe('Disk full');
    logs.follow.value = false;
    logs.offset.value = 0;
    await settle();
    expect(logs.page.value.entries[0]!.id).toBe(0);
    scope.stop();
    await flushPromises();

    const pending = deferred<number>();
    vi.spyOn(service, 'start').mockReturnValue(pending.promise);
    const stop = vi.spyOn(service, 'stop');
    const secondScope = effectScope();
    secondScope.run(() =>
      useLogcat(reactive({ deviceId: 'b', adbConnected: true, service })),
    );
    await flushPromises();
    secondScope.stop();
    pending.resolve(42);
    await flushPromises();
    expect(stop).toHaveBeenCalledWith(42);
  });

  it('maps a ten-million-line history below browser scroll-height limits without losing endpoints', () => {
    const total = 10000000;
    const height = 500;
    expect(scrollGeometry(total, height).scrollHeight).toBe(MAX_SCROLL_HEIGHT);
    for (const offset of [0, 10000, 5000000, total - 25]) {
      expect(
        scrollToOffset(offsetToScroll(offset, total, height), total, height),
      ).toBe(offset);
    }
  });
});
