import { createApp } from 'vue';
import { describe, expect, it, vi } from 'vitest';
import { createLocalLogger, initializeLocalLogging } from './localLogging';

const createTestApp = () => createApp({});

describe('Local diagnostics', () => {
  it('sends only the event identifier across IPC', async () => {
    const call = vi.fn().mockResolvedValue(undefined);
    await createLocalLogger(call).error('vue_error');
    expect(call).toHaveBeenCalledWith('log_frontend_event', {
      event: 'vue_error',
    });
  });

  it('preserves Vue reporting, excludes payloads and removes listeners', async () => {
    const app = createTestApp();
    const previous = vi.fn();
    app.config.errorHandler = previous;
    const logger = { error: vi.fn().mockResolvedValue(undefined) };
    const events = new EventTarget();
    const dispose = initializeLocalLogging(app, logger, events);
    const error = new Error('password=secret');
    app.config.errorHandler!(error, null, 'render');
    events.dispatchEvent(new Event('error'));
    events.dispatchEvent(new Event('unhandledrejection'));
    expect(previous).toHaveBeenCalledWith(error, null, 'render');
    expect(logger.error.mock.calls).toEqual([
      ['vue_error'],
      ['unhandled_error'],
      ['unhandled_rejection'],
    ]);
    dispose();
    events.dispatchEvent(new Event('error'));
    expect(logger.error).toHaveBeenCalledTimes(3);
    expect(app.config.errorHandler).toBe(previous);
  });

  it('contains logging failures without causing unhandled rejections', async () => {
    const app = createTestApp();
    const logger = {
      error: vi.fn().mockRejectedValue(new Error('IPC unavailable')),
    };
    const events = new EventTarget();
    const dispose = initializeLocalLogging(app, logger, events);
    events.dispatchEvent(new Event('error'));
    await Promise.resolve();
    expect(logger.error).toHaveBeenCalledTimes(1);
    dispose();
  });
});
