import { flushPromises, mount } from '@vue/test-utils'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import SettingsView from './SettingsView.vue'
import * as api from './api'
import { configureTelemetry } from '../../shared/telemetry'

vi.mock('./api', () => ({
  getSettings: vi.fn(),
  setCrashReporting: vi.fn(),
  openAppLog: vi.fn(),
  openProjectLink: vi.fn(),
  checkAppUpdates: vi.fn(),
}))
vi.mock('../../shared/telemetry', () => ({ configureTelemetry: vi.fn() }))

beforeEach(() => {
  vi.resetAllMocks()
  vi.mocked(api.getSettings).mockResolvedValue({ crashReportingEnabled: true, sentryDsn: 'dsn' })
})

describe('settings', () => {
  it('persists the opt-out before applying it to telemetry and restores it on reopening', async () => {
    const wrapper = mount(SettingsView)
    await flushPromises()
    await wrapper.get('[role="switch"]').trigger('click')
    await flushPromises()
    expect(api.setCrashReporting).toHaveBeenCalledWith(false)
    expect(configureTelemetry).toHaveBeenCalledWith({
      crashReportingEnabled: false,
      sentryDsn: 'dsn',
    })
    expect(wrapper.get('[role="switch"]').attributes('aria-checked')).toBe('false')
    wrapper.unmount()
    vi.mocked(api.getSettings).mockResolvedValue({ crashReportingEnabled: false, sentryDsn: 'dsn' })
    const reopened = mount(SettingsView)
    await flushPromises()
    expect(reopened.get('[role="switch"]').attributes('aria-checked')).toBe('false')
    reopened.unmount()
  })

  it('keeps the original preference when saving fails', async () => {
    vi.mocked(api.setCrashReporting).mockRejectedValue('Écriture impossible')
    const wrapper = mount(SettingsView)
    await flushPromises()
    await wrapper.get('[role="switch"]').trigger('click')
    await flushPromises()
    expect(wrapper.get('[role="switch"]').attributes('aria-checked')).toBe('true')
    expect(configureTelemetry).not.toHaveBeenCalled()
    expect(wrapper.get('[role="alert"]').text()).toContain('Écriture impossible')
    wrapper.unmount()
  })

  it('shows a release and clears stale results when a new check fails', async () => {
    vi.mocked(api.checkAppUpdates).mockResolvedValue({ status: 'available', version: '2027.1.0' })
    const wrapper = mount(SettingsView)
    await flushPromises()
    const button = wrapper
      .findAll('button')
      .find((item) => item.text() === 'Rechercher les mises à jour')!
    await button.trigger('click')
    await flushPromises()
    expect(wrapper.text()).toContain('2027.1.0')
    vi.mocked(api.checkAppUpdates).mockRejectedValue('Réseau indisponible')
    await button.trigger('click')
    await flushPromises()
    expect(wrapper.text()).not.toContain('2027.1.0')
    expect(wrapper.get('[role="alert"]').text()).toContain('Réseau indisponible')
    wrapper.unmount()
  })
})
