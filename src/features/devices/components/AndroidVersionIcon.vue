<script setup lang="ts">
import { computed } from 'vue'
import fallbackIcon from '../../../assets/android_versions/android.png'

const props = defineProps<{ version: string | null | undefined }>()

const icons = import.meta.glob<string>('../../../assets/android_versions/android_*.{png,svg}', {
  eager: true,
  query: '?url',
  import: 'default',
})

const icon = computed(() => {
  const majorVersion = props.version?.trim().match(/^(\d+)(?:\.|$)/)?.[1]
  const version = majorVersion === '2' ? '1' : majorVersion
  const basePath = `../../../assets/android_versions/android_${version}`
  return icons[`${basePath}.svg`] ?? icons[`${basePath}.png`] ?? fallbackIcon
})
</script>

<template>
  <img
    :src="icon"
    :alt="version ? `Android ${version}` : 'Android'"
    class="size-10 object-contain"
    width="40"
    height="40"
  />
</template>
