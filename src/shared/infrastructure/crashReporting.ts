import type { App } from 'vue';
import * as Sentry from '@sentry/vue';
import { invoke } from '@tauri-apps/api/core';

type SendError = (event: string) => Promise<unknown>;

/** The native client owns the DSN, release, transport and persisted consent. */
export function initializeCrashReporting(
  app: App,
  send: SendError = (event) => invoke('capture_frontend_error', { event }),
) {
  Sentry.init({
    app,
    // Required by the browser SDK; no request is made to this placeholder.
    dsn: 'https://public@localhost/1',
    sendClientReports: false,
    transport: () => ({
      send: async () => ({}),
      flush: async () => true,
    }),
    dataCollection: {
      userInfo: false,
      cookies: false,
      httpHeaders: false,
      httpBodies: [],
      urlQueryParams: false,
      stackFrameVariables: false,
    },
    defaultIntegrations: false,
    integrations: [Sentry.globalHandlersIntegration(), Sentry.vueIntegration()],
    attachProps: false,
    beforeSend: createNativeErrorForwarder(send),
  });
}

/** Always consume the event locally, including when the native bridge fails. */
export function createNativeErrorForwarder(send: SendError) {
  return async (event: Sentry.ErrorEvent): Promise<null> => {
    try {
      await send(JSON.stringify(event));
    } catch {
      // Reporting must not produce another unhandled error.
    }
    return null;
  };
}
