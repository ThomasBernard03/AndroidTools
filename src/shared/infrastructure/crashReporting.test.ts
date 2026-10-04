import { describe, expect, it, vi } from 'vitest';
import { createApp } from 'vue';
import * as Sentry from '@sentry/vue';
import {
  createNativeErrorForwarder,
  initializeCrashReporting,
} from './crashReporting';

describe('native crash reporting bridge', () => {
  it('forwards error details and consumes the browser event', async () => {
    const send = vi.fn().mockResolvedValue(undefined);
    const event = {
      type: undefined,
      exception: { values: [{ type: 'Error', value: 'Failure' }] },
    };
    expect(await createNativeErrorForwarder(send)(event)).toBeNull();
    expect(JSON.parse(send.mock.calls[0]![0] as string)).toEqual(event);
  });

  it('does not create an unhandled rejection when IPC is unavailable', async () => {
    const send = vi.fn().mockRejectedValue(new Error('Unavailable'));
    expect(
      await createNativeErrorForwarder(send)({ type: undefined }),
    ).toBeNull();
  });

  it('captures Vue failures without attaching component props', async () => {
    const send = vi.fn().mockResolvedValue(undefined);
    const app = createApp({});
    app.config.errorHandler = vi.fn();
    initializeCrashReporting(app, send);
    try {
      app.config.errorHandler?.(new Error('Vue failure'), null, 'render');
      await vi.waitFor(() => expect(send).toHaveBeenCalled());
      const event = JSON.parse(send.mock.calls[0]![0] as string);
      expect(event.exception.values[0].value).toBe('Vue failure');
      expect(event.contexts?.vue?.propsData).toBeUndefined();
    } finally {
      await Sentry.close();
    }
  });
});
