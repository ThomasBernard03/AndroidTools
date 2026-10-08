<script setup lang="ts">
import {
  ArrowUp,
  Check,
  ChevronDown,
  Copy,
  Download,
  Eye,
  EyeOff,
  FilePlus2,
  Folder,
  LayoutGrid,
  Package,
  Pencil,
  RefreshCw,
  Search,
  Settings,
  ShieldCheck,
  Smartphone,
  Sparkles,
  SquareTerminal,
  Trash2,
  Usb,
} from '@lucide/vue';

defineProps<{
  name: keyof typeof icons;
}>();

const icons = {
  phone: Smartphone,
  refresh: RefreshCw,
  chevron: ChevronDown,
  overview: LayoutGrid,
  usb: Usb,
  folder: Folder,
  search: Search,
  download: Download,
  rename: Pencil,
  trash: Trash2,
  'arrow-up': ArrowUp,
  terminal: SquareTerminal,
  package: Package,
  build: FilePlus2,
  eye: Eye,
  'eye-off': EyeOff,
  copy: Copy,
  sparkles: Sparkles,
  check: Check,
  settings: Settings,
  shield: ShieldCheck,
};
</script>

<template>
  <component
    :is="icons[name]"
    aria-hidden="true"
    focusable="false"
    :stroke-width="1.5"
  />
</template>
