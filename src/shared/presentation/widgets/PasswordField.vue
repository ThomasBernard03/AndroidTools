<script setup lang="ts">
import { ref, watch } from 'vue';
import AppIcon from './AppIcon.vue';

const props = defineProps<{
  id: string;
  label: string;
  modelValue: string;
  error?: string | undefined;
  canGenerate?: boolean;
  description?: string;
  copy: (text: string) => Promise<void>;
}>();
const emit = defineEmits<{
  'update:modelValue': [value: string];
  generate: [];
}>();
const visible = ref(false);
const feedback = ref('');
const copying = ref(false);
watch(
  () => props.modelValue,
  () => {
    feedback.value = '';
  },
);
async function copyValue() {
  copying.value = true;
  feedback.value = '';
  const value = props.modelValue;
  try {
    await props.copy(value);
    if (value === props.modelValue) feedback.value = 'Copied';
  } catch {
    feedback.value = 'Could not copy. Please retry.';
  } finally {
    copying.value = false;
  }
}
</script>

<template>
  <div>
    <label :for="id" class="mb-2 block text-sm">{{ label }}</label>
    <div class="relative">
      <input
        :id="id"
        :value="modelValue"
        :type="visible ? 'text' : 'password'"
        autocomplete="new-password"
        spellcheck="false"
        autocapitalize="off"
        :aria-invalid="!!error"
        :aria-describedby="
          [description ? `${id}-description` : '', error ? `${id}-error` : '']
            .filter(Boolean)
            .join(' ') || undefined
        "
        class="keystore-input"
        :class="canGenerate ? 'pr-28' : 'pr-20'"
        @input="
          emit('update:modelValue', ($event.target as HTMLInputElement).value)
        "
      />
      <div class="absolute inset-y-0 right-1.5 flex items-center gap-0.5">
        <button
          type="button"
          :aria-label="`${visible ? 'Hide' : 'Show'} ${label.toLowerCase()}`"
          :aria-pressed="visible"
          :title="`${visible ? 'Hide' : 'Show'} ${label.toLowerCase()}`"
          class="field-icon-button"
          @click="visible = !visible"
        >
          <AppIcon :name="visible ? 'eye-off' : 'eye'" class="size-4" />
        </button>
        <button
          type="button"
          class="field-icon-button"
          :aria-label="`Copy ${label.toLowerCase()}`"
          :title="
            feedback === 'Copied' ? 'Copied' : `Copy ${label.toLowerCase()}`
          "
          :disabled="!modelValue || copying"
          @click="copyValue"
        >
          <AppIcon
            :name="feedback === 'Copied' ? 'check' : 'copy'"
            class="size-4"
            :class="{ 'text-primary': feedback === 'Copied' }"
          />
        </button>
        <button
          v-if="canGenerate"
          type="button"
          class="field-icon-button"
          :aria-label="`Generate ${label.toLowerCase()}`"
          :title="`Generate ${label.toLowerCase()}`"
          @click="emit('generate')"
        >
          <AppIcon name="sparkles" class="size-4" />
        </button>
      </div>
    </div>
    <p
      v-if="description"
      :id="`${id}-description`"
      class="mt-2 text-xs leading-relaxed text-muted"
    >
      {{ description }}
    </p>
    <p v-if="error" :id="`${id}-error`" class="mt-1 text-xs text-danger">
      {{ error }}
    </p>
    <p v-if="feedback" role="status" class="mt-1 text-xs text-muted">
      {{ feedback }}
    </p>
  </div>
</template>
