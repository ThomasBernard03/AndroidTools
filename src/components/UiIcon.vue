<script setup lang="ts">
withDefaults(defineProps<{ name: keyof typeof paths; size?: number }>(), { size: 16 })

const paths = {
  folder: 'M3 7V5a1 1 0 0 1 1-1h5l2 3h9a1 1 0 0 1 1 1v11a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V7Z',
  file: 'M14 2H5v20h14V7l-5-5Zm0 0v5h5M8 12h8m-8 4h6',
  up: 'M12 20V4m-6 6 6-6 6 6',
  close: 'm6 6 12 12M6 18 18 6',
  link: 'm10 13 4-4m-6 7-1 1a4 4 0 0 1-6-6l4-4a4 4 0 0 1 6 0m2 1 1-1a4 4 0 0 1 6 6l-4 4a4 4 0 0 1-6 0',
  package: 'm12 3 9 5v8l-9 5-9-5V8l9-5Zm0 9 9-4m-9 4L3 8m9 4v9M7.5 5.5l9 5v4',
  upload: 'M12 16V3m-5 5 5-5 5 5M4 15v5h16v-5',
  phone:
    'M8 2.75h8a2 2 0 0 1 2 2v14.5a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2V4.75a2 2 0 0 1 2-2Zm2 3h4m-3 12.5h2',
  grid: 'M3.75 3.75h6.5v6.5h-6.5Zm10 0h6.5v6.5h-6.5Zm-10 10h6.5v6.5h-6.5Zm10 0h6.5v6.5h-6.5Z',
  refresh: 'M20 10a8 8 0 0 0-14-4L3.5 8.5m0-5v5h5M4 14a8 8 0 0 0 14 4l2.5-2.5m0 5v-5h-5',
  chevron: 'm9 5 7 7-7 7',
  down: 'm8 10 4 4 4-4',
  cable: 'M9 3v4m6-4v4M7 7h10v3a5 5 0 0 1-10 0V7Zm5 8v3a3 3 0 0 0 3 3h3',
  info: 'M12 16v-4m0-4h.01M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z',
  cpu: 'M7 7h10v10H7Zm3 3h4v4h-4ZM9 3v4m6-4v4M9 17v4m6-4v4M3 9h4m-4 6h4m10-6h4m-4 6h4',
  system: 'M5 4h14v12H5Zm3 16h8m-4-4v4M8 8h8m-8 4h5',
  shield: 'M12 3 4 6v5c0 5 8 10 8 10s8-5 8-10V6l-8-3Zm-4 9 3 3 5-6',
  code: 'm8 7-5 5 5 5m8-10 5 5-5 5m-3-13-2 16',
  check: 'm5 12 4 4L19 6',
  warning:
    'M12 8v5m0 3h.01M10.3 4.5 2.7 18a1.5 1.5 0 0 0 1.3 2h16a1.5 1.5 0 0 0 1.3-2L13.7 4.5a2 2 0 0 0-3.4 0Z',
}
</script>

<template>
  <svg
    :width="size"
    :height="size"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    stroke-width="1.5"
    stroke-linecap="round"
    stroke-linejoin="round"
    aria-hidden="true"
    class="shrink-0"
  >
    <path :d="paths[name]" />
  </svg>
</template>
