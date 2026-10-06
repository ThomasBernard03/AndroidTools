<script setup lang="ts">
import { onMounted, onBeforeUnmount, ref } from 'vue';
import AppIcon from '../../../shared/presentation/widgets/AppIcon.vue';
import type { FileEntry } from '../domain/files';

const props = defineProps<{
  entry: FileEntry;
  actionable: boolean;
  x: number;
  y: number;
}>();
const emit = defineEmits<{
  action: [action: 'open' | 'download' | 'rename' | 'delete'];
  close: [];
}>();
const menu = ref<HTMLElement>();
const left = ref(props.x);
const top = ref(props.y);
const previousFocus = document.activeElement;

function dismiss(event: Event) {
  if (!menu.value?.contains(event.target as Node)) emit('close');
}
function close() {
  emit('close');
}
function keydown(event: KeyboardEvent) {
  if (event.key === 'Escape' || event.key === 'Tab') {
    if (event.key === 'Escape') event.preventDefault();
    close();
    return;
  }
  const buttons = Array.from(menu.value?.querySelectorAll('button') ?? []);
  if (!buttons.length) return;
  const index = buttons.indexOf(document.activeElement as HTMLButtonElement);
  let next: number;
  switch (event.key) {
    case 'ArrowDown':
      next = (index + 1) % buttons.length;
      break;
    case 'ArrowUp':
      next = (index - 1 + buttons.length) % buttons.length;
      break;
    case 'Home':
      next = 0;
      break;
    case 'End':
      next = buttons.length - 1;
      break;
    default:
      return;
  }
  event.preventDefault();
  buttons[next]?.focus();
}
onMounted(() => {
  const bounds = menu.value!.getBoundingClientRect();
  left.value = Math.max(
    8,
    Math.min(props.x, window.innerWidth - bounds.width - 8),
  );
  top.value = Math.max(
    8,
    Math.min(props.y, window.innerHeight - bounds.height - 8),
  );
  (menu.value!.querySelector('button') ?? menu.value)!.focus();
  window.addEventListener('pointerdown', dismiss, true);
  window.addEventListener('scroll', close, true);
  window.addEventListener('resize', close);
});
onBeforeUnmount(() => {
  if (
    menu.value?.contains(document.activeElement) &&
    previousFocus instanceof HTMLElement
  )
    previousFocus.focus();
  window.removeEventListener('pointerdown', dismiss, true);
  window.removeEventListener('scroll', close, true);
  window.removeEventListener('resize', close);
});
</script>

<template>
  <Teleport to="body">
    <div
      ref="menu"
      role="menu"
      :aria-label="`Actions for ${entry.name}`"
      tabindex="-1"
      class="fixed z-50 min-w-44 max-w-[calc(100vw-16px)] rounded-lg border border-stroke bg-surface-raised p-1 shadow-xl"
      :style="{ left: `${left}px`, top: `${top}px` }"
      @keydown="keydown"
      @contextmenu.prevent
    >
      <button
        v-if="entry.kind === 'directory'"
        role="menuitem"
        class="menu-action"
        @click="emit('action', 'open')"
      >
        <AppIcon name="folder" class="size-4" /> Open
      </button>
      <template v-if="actionable">
        <button
          role="menuitem"
          class="menu-action"
          @click="emit('action', 'download')"
        >
          <AppIcon name="download" class="size-4" /> Download
        </button>
        <button
          role="menuitem"
          class="menu-action"
          @click="emit('action', 'rename')"
        >
          <AppIcon name="rename" class="size-4" /> Rename
        </button>
        <button
          role="menuitem"
          class="menu-action text-danger"
          @click="emit('action', 'delete')"
        >
          <AppIcon name="trash" class="size-4" /> Delete
        </button>
      </template>
      <p
        v-else-if="entry.kind !== 'directory'"
        class="px-3 py-2 text-xs text-muted"
      >
        No available actions
      </p>
    </div>
  </Teleport>
</template>

<style scoped>
@reference '../../../styles.css';
.menu-action {
  @apply flex w-full items-center gap-2 rounded px-3 py-2 text-left text-xs hover:bg-primary/10 focus-visible:bg-primary/10 focus-visible:outline-offset-0;
}
</style>
