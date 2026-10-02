import { createApp } from 'vue'
import App from './App.vue'
import './style.css'
import { getSettings } from './features/settings/api'
import { configureTelemetry } from './shared/telemetry'

async function start() {
  const app = createApp(App)
  configureTelemetry({ crashReportingEnabled: false, sentryDsn: null }, app)
  try {
    configureTelemetry(await getSettings(), app)
  } catch {
    console.error('Impossible de charger les réglages de crash reporting. Sentry reste désactivé.')
  }
  app.mount('#app')
}
void start()
