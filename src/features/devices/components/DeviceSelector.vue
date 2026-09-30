<script setup lang="ts">
import UiIcon from '../../../components/UiIcon.vue'
import type { DeviceSummary } from '../types'

defineProps<{ devices: DeviceSummary[]; scanning: boolean }>()
const selectedId = defineModel<string>({ required: true })
defineEmits<{ refresh: [] }>()
</script>

<template>
  <section aria-labelledby="devices-heading">
    <div class="mb-2 flex items-center justify-between px-2">
      <h2 id="devices-heading" class="section-label">
        Appareils connectés <span class="ml-1 text-muted/70">{{ devices.length }}</span>
      </h2>
      <button
        type="button"
        class="icon-button"
        :disabled="scanning"
        :aria-label="scanning ? 'Recherche des appareils…' : 'Actualiser les appareils'"
        title="Actualiser les appareils"
        @click="$emit('refresh')"
      >
        <UiIcon name="refresh" :size="13" :class="{ 'animate-spin': scanning }" />
      </button>
    </div>
    <label for="device-selector" class="sr-only">Appareil à inspecter</label>
    <div class="relative">
      <UiIcon
        name="phone"
        class="pointer-events-none absolute left-2.5 top-3 text-muted"
        :size="14"
      />
      <select
        id="device-selector"
        v-model="selectedId"
        :disabled="devices.length === 0"
        class="min-h-10 w-full appearance-none truncate rounded-md border border-line bg-raised/50 py-2.5 pl-8 pr-7 text-xs text-ink transition-colors hover:bg-raised disabled:text-muted disabled:hover:bg-raised/50"
      >
        <option value="">
          {{ devices.length ? 'Sélectionner un appareil' : 'Aucun appareil détecté' }}
        </option>
        <option v-for="device in devices" :key="device.id" :value="device.id">
          {{ device.name }}{{ device.serial ? ` · ${device.serial}` : '' }} · USB
          {{ device.usbLocation }}{{ device.accessError ? ' · Accès limité' : '' }}
        </option>
      </select>
      <UiIcon
        name="down"
        class="pointer-events-none absolute right-2 top-3 text-muted"
        :size="14"
      />
    </div>
    <p class="mt-2 px-2 text-[11px] leading-4 text-muted">
      {{ scanning ? 'Recherche en cours…' : 'Actualisez après un branchement' }}
    </p>
  </section>
</template>
