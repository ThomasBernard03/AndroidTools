<script setup lang="ts">
import { ref, useId } from 'vue'
import { chooseToolFile } from '../api'
import { toAppError, type AppError } from '../../../shared/errors'
import ErrorNotice from '../../../components/ErrorNotice.vue'

const model = defineModel<string>({ required: true })
const props = defineProps<{ label: string; extensions?: string[]; disabled?: boolean }>()
const error = ref<AppError | null>(null)
const choosing = ref(false)
const id = useId()
async function browse() {
  choosing.value = true
  error.value = null
  try {
    const path = await chooseToolFile(props.label, props.extensions)
    if (path) model.value = path
  } catch (cause) {
    error.value = toAppError(cause)
  } finally {
    choosing.value = false
  }
}
</script>

<template>
  <div class="space-y-2">
    <label :for="id" class="block text-secondary">{{ label }}</label>
    <div class="flex gap-2">
      <input
        :id="id"
        v-model="model"
        class="form-input min-w-0 flex-1"
        required
        :disabled="disabled || choosing"
        placeholder="Chemin absolu du fichier"
      />
      <button
        type="button"
        class="button"
        :disabled="disabled || choosing"
        :aria-label="`Parcourir : ${label}`"
        @click="browse"
      >
        Parcourir…
      </button>
    </div>
    <ErrorNotice v-if="error" :error="error" />
  </div>
</template>
