import { createApp } from 'vue'
import { beforeEach, expect, it, vi } from 'vitest'
import * as Sentry from '@sentry/vue'

vi.mock('@sentry/vue', () => ({ init: vi.fn(), getClient: vi.fn() }))

beforeEach(() => {
  vi.resetModules()
  vi.resetAllMocks()
})

it('does not initialize on opt-out, then gates events immediately when disabled again', async () => {
  const { configureTelemetry } = await import('./telemetry')
  const settings = { crashReportingEnabled: false, sentryDsn: 'dsn' }
  configureTelemetry(settings, createApp({}))
  expect(Sentry.init).not.toHaveBeenCalled()
  configureTelemetry({ ...settings, crashReportingEnabled: true })
  const options = vi.mocked(Sentry.init).mock.calls[0]![0]!
  const event = {
    type: undefined,
    message: 'Unexpected error',
    extra: { password: 'secret' },
    request: { url: 'local' },
  }
  const beforeSend = options.beforeSend!
  expect(beforeSend(event, {})).toEqual({ message: 'Unexpected error' })
  configureTelemetry(settings)
  expect(beforeSend({ type: undefined, message: 'After opt-out' }, {})).toBeNull()
})
