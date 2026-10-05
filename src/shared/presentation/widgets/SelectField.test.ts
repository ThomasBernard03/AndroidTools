import { mount } from '@vue/test-utils';
import { describe, expect, it } from 'vitest';
import SelectField from './SelectField.vue';

const props = {
  id: 'format',
  label: 'Format',
  modelValue: 'JKS',
  options: [
    { value: 'JKS', label: 'JKS', description: 'Java KeyStore' },
    { value: 'PKCS12', label: 'PKCS12', description: 'Standard format' },
  ],
};

describe('Custom select', () => {
  it('selects an option using the pointer and exposes its expanded and selected states', async () => {
    const wrapper = mount(SelectField, { props });
    const trigger = wrapper.get('[role="combobox"]');
    expect(trigger.attributes('aria-expanded')).toBe('false');
    await trigger.trigger('click');
    expect(trigger.attributes('aria-expanded')).toBe('true');
    expect(wrapper.get('[aria-selected="true"]').text()).toContain('JKS');
    await wrapper.get('#format-option-1').trigger('click');
    expect(wrapper.emitted('update:modelValue')).toEqual([['PKCS12']]);
    expect(wrapper.find('[role="listbox"]').exists()).toBe(false);
    wrapper.unmount();
  });

  it('supports keyboard navigation, typeahead, selection and cancellation', async () => {
    const wrapper = mount(SelectField, { props });
    const trigger = wrapper.get('[role="combobox"]');
    await trigger.trigger('keydown', { key: 'ArrowDown' });
    await trigger.trigger('keydown', { key: 'End' });
    expect(trigger.attributes('aria-activedescendant')).toBe('format-option-1');
    await trigger.trigger('keydown', { key: 'Home' });
    expect(trigger.attributes('aria-activedescendant')).toBe('format-option-0');
    await trigger.trigger('keydown', { key: 'p' });
    expect(trigger.attributes('aria-activedescendant')).toBe('format-option-1');
    await trigger.trigger('keydown', { key: 'Escape' });
    expect(wrapper.emitted('update:modelValue')).toBeUndefined();
    await trigger.trigger('keydown', { key: ' ' });
    await trigger.trigger('keydown', { key: 'ArrowDown' });
    await trigger.trigger('keydown', { key: 'Enter' });
    expect(wrapper.emitted('update:modelValue')).toEqual([['PKCS12']]);
    await trigger.trigger('click');
    await trigger.trigger('keydown', { key: 'Tab' });
    expect(trigger.attributes('aria-expanded')).toBe('false');
    wrapper.unmount();
  });

  it('closes outside the control and cannot open or select when disabled', async () => {
    const wrapper = mount(SelectField, { props, attachTo: document.body });
    const trigger = wrapper.get('[role="combobox"]');
    await trigger.trigger('click');
    document.body.dispatchEvent(
      new PointerEvent('pointerdown', { bubbles: true }),
    );
    await wrapper.vm.$nextTick();
    expect(trigger.attributes('aria-expanded')).toBe('false');
    await trigger.trigger('click');
    await wrapper.setProps({ disabled: true });
    expect(trigger.attributes('aria-expanded')).toBe('false');
    await trigger.trigger('keydown', { key: 'Enter' });
    expect(wrapper.find('[role="listbox"]').exists()).toBe(false);
    expect(wrapper.emitted('update:modelValue')).toBeUndefined();
    wrapper.unmount();
  });
});
