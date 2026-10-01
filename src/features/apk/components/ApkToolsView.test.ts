import { flushPromises, mount } from '@vue/test-utils'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import ApkToolsView from './ApkToolsView.vue'
import { chooseToolOutput, generateKeystore, signApk } from '../api'

vi.mock('../api', () => ({
  chooseToolOutput: vi.fn(),
  chooseToolFile: vi.fn(),
  generateKeystore: vi.fn(),
  signApk: vi.fn(),
}))

beforeEach(() => {
  vi.resetAllMocks()
})

async function fillKeystore(wrapper: ReturnType<typeof mount>) {
  const form = wrapper.findAll('form')[0]!
  await form.findAll('input')[2]!.setValue('CN=Test, C=FR')
  await form.findAll('input[type="password"]')[0]!.setValue('secret123')
  await form.findAll('input[type="password"]')[1]!.setValue('secret123')
  return form
}

describe('APK tools', () => {
  it('shows the duration and expiration and hides them for invalid validity', async () => {
    vi.spyOn(Date, 'now').mockReturnValue(new Date('2026-01-01T12:00:00Z').getTime())
    const wrapper = mount(ApkToolsView, { props: { mode: 'keystore' } })
    try {
      const days = wrapper.get('input[type="number"]')
      await days.setValue(365)
      expect(wrapper.get('#keystore-validity').text()).toContain('365 jours (environ 1 an)')
      expect(wrapper.get('#keystore-validity').text()).toContain('Expiration : 1 janvier 2027')
      await days.setValue(0)
      expect(wrapper.find('#keystore-validity').exists()).toBe(false)
      await days.setValue(36501)
      expect(wrapper.find('#keystore-validity').exists()).toBe(false)
    } finally {
      vi.restoreAllMocks()
      wrapper.unmount()
    }
  })

  it('generates matching passwords and submits them with the keystore', async () => {
    vi.mocked(chooseToolOutput).mockResolvedValue('/release.p12')
    vi.mocked(generateKeystore).mockResolvedValue('/release.p12')
    const wrapper = mount(ApkToolsView, { props: { mode: 'keystore' } })
    const form = await fillKeystore(wrapper)
    const generate = form
      .findAll('button')
      .find((button) => button.text() === 'Générer un mot de passe')!
    await generate.trigger('click')
    const passwords = form.findAll('input[type="password"]')
    const password = (passwords[0]!.element as HTMLInputElement).value
    expect(password).toMatch(/^[A-Za-z0-9_-]{24}$/)
    expect((passwords[1]!.element as HTMLInputElement).value).toBe(password)
    await form.trigger('submit')
    await flushPromises()
    expect(generateKeystore).toHaveBeenCalledWith(expect.objectContaining({ password }))
    expect(form.text()).toContain('/release.p12.json')
    wrapper.unmount()
  })

  it('generates a keystore, clears passwords and reuses the key for signing', async () => {
    vi.mocked(chooseToolOutput).mockResolvedValue('/release.p12')
    vi.mocked(generateKeystore).mockResolvedValue('/release.p12')
    const wrapper = mount(ApkToolsView, { props: { mode: 'keystore' } })
    await flushPromises()
    const form = await fillKeystore(wrapper)
    await form.trigger('submit')
    await flushPromises()
    expect(generateKeystore).toHaveBeenCalledWith(
      expect.objectContaining({
        outputPath: '/release.p12',
        password: 'secret123',
        commonName: 'CN=Test, C=FR',
      }),
    )
    expect(form.text()).toContain('Keystore généré avec succès')
    expect((form.get('input[type="password"]').element as HTMLInputElement).value).toBe('')
    await wrapper.setProps({ mode: 'sign' })
    const sign = wrapper.findAll('form')[1]!
    expect((sign.findAll('input')[1]!.element as HTMLInputElement).value).toBe('/release.p12')
    wrapper.unmount()
  })

  it('does not invoke generation when the save dialog is cancelled', async () => {
    vi.mocked(chooseToolOutput).mockResolvedValue(null)
    const wrapper = mount(ApkToolsView, { props: { mode: 'keystore' } })
    await flushPromises()
    await (await fillKeystore(wrapper)).trigger('submit')
    await flushPromises()
    expect(generateKeystore).not.toHaveBeenCalled()
    wrapper.unmount()
  })

  it('coalesces submissions and shows signing errors without retaining passwords', async () => {
    let reject!: (reason: unknown) => void
    vi.mocked(chooseToolOutput).mockResolvedValue('/signed.apk')
    vi.mocked(signApk).mockReturnValue(
      new Promise((_, fail) => {
        reject = fail
      }),
    )
    const wrapper = mount(ApkToolsView, { props: { mode: 'sign' } })
    await flushPromises()
    const form = wrapper.findAll('form')[1]!
    const inputs = form.findAll('input')
    await inputs[0]!.setValue('/source.apk')
    await inputs[1]!.setValue('/release.p12')
    await inputs[3]!.setValue('wrong-password')
    await form.trigger('submit')
    await flushPromises()
    await form.trigger('submit')
    expect(signApk).toHaveBeenCalledTimes(1)
    reject({
      code: 'apk_tools',
      message: 'Signature impossible',
      details: 'Mot de passe incorrect',
    })
    await flushPromises()
    expect(form.get('[role="alert"]').text()).toContain('Signature impossible')
    expect((inputs[3]!.element as HTMLInputElement).value).toBe('')
    wrapper.unmount()
  })
})
