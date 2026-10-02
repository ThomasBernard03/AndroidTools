<script setup lang="ts">
import { ref } from 'vue'

defineProps<{ label: string; required?: boolean }>()
const model = defineModel<string>({ required: true })
const visible = ref(false)
</script>

<template>
  <div class="space-y-2">
    <label class="block space-y-2">
      <span class="block text-secondary">{{ label }}</span>
      <input
        v-model="model"
        :type="visible ? 'text' : 'password'"
        autocomplete="off"
        spellcheck="false"
        :required="required"
        class="form-input w-full"
      />
    </label>
    <button
      type="button"
      class="button text-xs"
      :aria-label="`${visible ? 'Masquer' : 'Afficher'} : ${label}`"
      :aria-pressed="visible"
      @click="visible = !visible"
    >
      {{ visible ? 'Masquer' : 'Afficher' }} le mot de passe
    </button>
  </div>
</template>
