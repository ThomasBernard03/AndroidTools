import { invoke } from '@tauri-apps/api/core';
import type { App } from 'vue';

export type FrontendLogEvent =
  'vue_error' | 'unhandled_error' | 'unhandled_rejection';

export interface LocalLogger {
  error(event: FrontendLogEvent): Promise<void>;
}

export function createLocalLogger(call: typeof invoke = invoke): LocalLogger {
  return {
    async error(event) {
      // Never serialize Error objects, component state or rejection payloads.
      await call('log_frontend_event', { event });
    },
  };
}

/** Installs local diagnostics while preserving existing Vue error integrations. */
export function initializeLocalLogging(
  app: App,
  logger: LocalLogger = createLocalLogger(),
  events: EventTarget = window,
): () => void {
  const report = (event: FrontendLogEvent) => {
    // A failed logging IPC must not generate another unhandled rejection.
    void logger.error(event).catch(() => {});
  };
  const previous = app.config.errorHandler;
  const handler: NonNullable<App['config']['errorHandler']> = (
    error,
    instance,
    info,
  ) => {
    report('vue_error');
    if (previous) previous(error, instance, info);
    else console.error(error);
  };
  const onError = () => report('unhandled_error');
  const onRejection = () => report('unhandled_rejection');
  app.config.errorHandler = handler;
  events.addEventListener('error', onError);
  events.addEventListener('unhandledrejection', onRejection);
  const dispose = () => {
    events.removeEventListener('error', onError);
    events.removeEventListener('unhandledrejection', onRejection);
    if (app.config.errorHandler === handler) {
      if (previous) app.config.errorHandler = previous;
      else delete app.config.errorHandler;
    }
  };
  app.onUnmount(dispose);
  return dispose;
}
