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
  it('opens the APK tools without a connected device and preserves the forms across navigation', async () => {
    vi.mocked(listDevices).mockResolvedValue([])
    const wrapper = mount(App)
    try {
      await flushPromises()
      const navigation = wrapper.get('nav')
      const keystore = navigation
        .findAll('button')
        .find((button) => button.text() === 'Génération de keystore')!
      const sign = navigation
        .findAll('button')
        .find((button) => button.text() === 'Signature d’APK')!
      await keystore.trigger('click')
      const alias = wrapper.findAll('form')[0]!.findAll('input')[0]!
      await alias.setValue('my-release')
      expect(keystore.attributes('aria-current')).toBe('page')
      await sign.trigger('click')
      expect(sign.attributes('aria-current')).toBe('page')
      expect(wrapper.findAll('form')[1]!.isVisible()).toBe(true)
      await keystore.trigger('click')
      expect((alias.element as HTMLInputElement).value).toBe('my-release')
    } finally {
      wrapper.unmount()
    }
  })

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
