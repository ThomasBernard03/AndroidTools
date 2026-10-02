import type { App } from 'vue'
import * as Sentry from '@sentry/vue'
import { version } from '../../src-tauri/tauri.conf.json'
import type { AppSettings } from '../features/settings/api'

let app: App | undefined
let reportingEnabled = false

export function configureTelemetry(settings: AppSettings, vueApp?: App) {
  app = vueApp ?? app
  reportingEnabled = settings.crashReportingEnabled
  if (!settings.sentryDsn || !app) return
  const client = Sentry.getClient()
  if (client) {
    client.getOptions().enabled = reportingEnabled
    return
  }
  if (!reportingEnabled) return
  Sentry.init({
    app,
    dsn: settings.sentryDsn,
    release: `android-tools@${version}`,
    sendDefaultPii: false,
    attachProps: false,
    sendClientReports: false,
    tracesSampleRate: 0,
    // Do not collect form interactions, console content or network breadcrumbs.
    integrations: (defaults) =>
      defaults.filter(
        (integration) => !['Breadcrumbs', 'BrowserSession'].includes(integration.name),
      ),
    beforeSend(event) {
      if (!reportingEnabled) return null
      delete event.breadcrumbs
      delete event.request
      delete event.user
      delete event.extra
      return event
    },
  })
}
