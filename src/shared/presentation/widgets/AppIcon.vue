<script setup lang="ts">
defineProps<{
  name:
    | 'phone'
    | 'refresh'
    | 'chevron'
    | 'overview'
    | 'usb'
    | 'folder'
    | 'terminal'
    | 'package'
    | 'build'
    | 'shield';
}>();

const paths = {
  folder: 'M3 7V5h6l2 2h10v13H3V7Z',
  terminal: 'M3 4h18v16H3V4Zm4 4 4 4-4 4m6 0h4',
  package: 'm12 3 9 5v9l-9 5-9-5V8l9-5Zm-9 5 9 5 9-5m-9 5v9M7.5 5.5l9 5',
  build: 'M4 4h10v16H4V4Zm3 4h4m-4 4h4m6 0v8m-4-4h8',
  shield: 'm12 3 8 3v6c0 5-8 9-8 9s-8-4-8-9V6l8-3Zm-4 9 3 3 5-6',
  phone:
    'M8 3h8a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2Zm2 3h4m-3 12h2',
  refresh:
    'M20 7v5h-5M4 17v-5h5M6.1 7a7 7 0 0 1 11.5-1L20 9M4 15l2.4 3A7 7 0 0 0 17.9 17',
  chevron: 'm7 10 5 5 5-5',
  overview: 'M3 3h7v7H3V3Zm11 0h7v7h-7V3ZM3 14h7v7H3v-7Zm11 0h7v7h-7v-7Z',
  usb: 'M12 21V3m-3 3 3-3 3 3M12 16l-5-4V8m5 5 5-4V6M5 6h4v2H5V6Zm10-3h4v3h-4V3Z',
};
</script>

<template>
  <svg
    aria-hidden="true"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    stroke-width="1.5"
    stroke-linecap="round"
    stroke-linejoin="round"
  >
    <path :d="paths[name]" />
  </svg>
</template>
