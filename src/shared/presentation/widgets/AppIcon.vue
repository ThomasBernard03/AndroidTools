<script setup lang="ts">
defineProps<{
  name:
    | 'phone'
    | 'refresh'
    | 'chevron'
    | 'overview'
    | 'usb'
    | 'folder'
    | 'search'
    | 'download'
    | 'rename'
    | 'trash'
    | 'arrow-up'
    | 'terminal'
    | 'package'
    | 'build'
    | 'eye'
    | 'eye-off'
    | 'copy'
    | 'sparkles'
    | 'check'
    | 'settings'
    | 'shield';
}>();

const paths = {
  download: 'M12 3v12m-5-5 5 5 5-5M4 16v5h16v-5',
  rename: 'm15 4 5 5M4 20l5-1L21 7l-5-5L4 14v6Z',
  trash: 'M3 6h18M9 6V3h6v3M5 6l1 15h12l1-15M10 10v7m4-7v7',
  'arrow-up': 'M12 21V3m-7 7 7-7 7 7',
  settings:
    'M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8Zm-2-5h4l1 3 3-1 2 3-2 3 2 3-2 3-3-1-1 3h-4l-1-3-3 1-2-3 2-3-2-3 2-3 3 1 1-3Z',
  eye: 'M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12Zm13 0a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z',
  'eye-off':
    'm3 3 18 18M10.6 5.1 12 5c6.5 0 10 7 10 7a19 19 0 0 1-3 3.8M6 6.5A20 20 0 0 0 2 12s3.5 7 10 7a12 12 0 0 0 5.2-1.2M9.9 9.9a3 3 0 0 0 4.2 4.2',
  copy: 'M9 9h11v12H9V9ZM5 16H3V3h12v2',
  sparkles:
    'm12 3 2.5 6.5L21 12l-6.5 2.5L12 21l-2.5-6.5L3 12l6.5-2.5L12 3Zm7-1v4m-2-2h4M4 18v4m-2-2h4',
  check: 'm5 12 4 4L19 6',
  folder: 'M3 7V5h6l2 2h10v13H3V7Z',
  search: 'M17 10a7 7 0 1 1-14 0 7 7 0 0 1 14 0Zm-2 5 6 6',
  terminal: 'M3 4h18v16H3V4Zm4 4 4 4-4 4m6 0h4',
  package: 'm12 3 9 5v9l-9 5-9-5V8l9-5Zm-9 5 9 5 9-5m-9 5v9M7.5 5.5l9 5',
  build: 'M4 4h10v16H4V4Zm3 4h4m-4 4h4m6 0v8m-4-4h8',
  shield: 'm12 3 8 3v6c0 5-8 9-8 9s-8-4-8-9V6l8-3Zm-4 9 3 3 5-6',
  phone:
    'M8 3h8a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2Zm2 3h4m-3 12h2',
  refresh:
    'M3 12a9 9 0 0 1 9-9c2.52 0 4.93 1 6.74 2.74L21 8m0-5v5h-5M21 12a9 9 0 0 1-9 9c-2.52 0-4.93-1-6.74-2.74L3 16m5 0H3v5',
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
