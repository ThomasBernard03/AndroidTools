import { flushPromises, mount } from '@vue/test-utils'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { getDeviceInfo, listDevices } from './features/devices/api'
import App from './App.vue'

vi.mock('./features/devices/api', async (importOriginal) => ({
  ...(await importOriginal<typeof import('./features/devices/api')>()),
  listDevices: vi.fn(),
  getDeviceInfo: vi.fn(),
}))

afterEach(() => vi.resetAllMocks())

describe('device screen', () => {
  it('explains how to connect a device when the list is empty', async () => {
    vi.mocked(listDevices).mockResolvedValue([])
    const wrapper = mount(App)
    try {
      await flushPromises()
      expect(wrapper.get('select').attributes('disabled')).toBeDefined()
      expect(wrapper.text()).toContain('Connectez un appareil Android')
      expect(wrapper.text()).toContain('débogage USB')
    } finally {
      wrapper.unmount()
    }
  })

  it('selects by USB identity and offers retry on connection failure', async () => {
    vi.mocked(listDevices).mockResolvedValue([
      {
        id: 'usb:1:2',
        name: 'Pixel',
        serial: 'ABC',
        usbLocation: '1:2',
        vendorId: '18d1',
        productId: '4ee7',
        accessError: null,
      },
    ])
    vi.mocked(getDeviceInfo).mockRejectedValue({
      code: 'busy',
      message: 'Interface USB occupée',
      details: 'DeviceBusy',
    })
    const wrapper = mount(App)
    try {
      await flushPromises()
      await wrapper.get('select').setValue('usb:1:2')
      await flushPromises()
      expect(getDeviceInfo).toHaveBeenCalledWith('usb:1:2')
      expect(wrapper.get('[role="alert"]').text()).toContain('Interface USB occupée')
      expect(wrapper.findAll('button').some((button) => button.text() === 'Réessayer')).toBe(true)
    } finally {
      wrapper.unmount()
    }
  })
})
