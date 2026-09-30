<script setup lang="ts">
import UiIcon from '../../../components/UiIcon.vue'

defineProps<{
  title: string
  icon: 'phone' | 'system' | 'cpu' | 'cable'
  entries: { label: string; value: string | null }[]
}>()
</script>

<template>
  <section class="min-w-0">
    <h4 class="mb-3 flex items-center gap-2 border-b border-line pb-3 text-xs font-medium">
      <UiIcon :name="icon" :size="14" class="text-muted" />{{ title }}
    </h4>
    <dl>
      <div
        v-for="entry in entries"
        :key="entry.label"
        class="grid grid-cols-[minmax(0,1fr)_minmax(0,1.25fr)] gap-3 rounded px-1 py-2 text-xs transition-colors hover:bg-raised/60"
      >
        <dt class="text-secondary">{{ entry.label }}</dt>
        <dd class="min-w-0 break-words text-right leading-5 text-ink [overflow-wrap:anywhere]">
          <template v-if="entry.value">{{ entry.value }}</template>
          <span v-else class="text-muted">Non disponible</span>
        </dd>
      </div>
    </dl>
  </section>
</template>
