<script setup lang="ts">
import type { AppError } from '../shared/errors'
import UiIcon from './UiIcon.vue'

defineProps<{ error: AppError }>()
</script>

<template>
  <div
    role="alert"
    class="rounded-lg border border-amber-300/15 bg-amber-200/4 p-4 text-xs leading-5 text-[#e6c998]"
  >
    <p class="flex items-start gap-2.5">
      <UiIcon name="warning" :size="15" class="mt-0.5" />{{ error.message }}
    </p>
    <details v-if="error.details" class="mt-3 pl-6 text-secondary">
      <summary class="cursor-pointer">Détails techniques</summary>
      <pre class="mt-2 whitespace-pre-wrap break-all font-mono text-[11px]">{{
        error.details
      }}</pre>
    </details>
  </div>
</template>
