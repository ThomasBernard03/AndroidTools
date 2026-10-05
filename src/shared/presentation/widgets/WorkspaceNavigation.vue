<script setup lang="ts">
import { workspacePages, type WorkspacePage } from '../workspaceNavigation';
import AppIcon from './AppIcon.vue';

defineProps<{ current: WorkspacePage['id'] }>();
defineEmits<{ navigate: [page: WorkspacePage] }>();
</script>

<template>
  <nav aria-label="Workspace" class="flex flex-1 flex-col gap-6 px-3 pt-7">
    <div
      v-for="group in ['Device', 'APK & Keystore', 'Application']"
      :key="group"
      :class="
        group === 'Application' ? 'mt-auto border-t border-stroke pt-3' : ''
      "
    >
      <p
        v-if="group !== 'Application'"
        class="mb-2 px-2.5 text-[10px] font-semibold tracking-[0.16em] text-muted uppercase"
      >
        {{ group }}
      </p>
      <div class="space-y-1">
        <button
          v-for="page in workspacePages.filter(
            (entry) => entry.group === group,
          )"
          :key="page.id"
          type="button"
          :aria-current="current === page.id ? 'page' : undefined"
          class="flex w-full items-center gap-2.5 rounded-md px-2.5 py-2 text-left text-[13px] font-medium transition-colors hover:bg-surface motion-reduce:transition-none"
          :class="
            current === page.id ? 'bg-surface text-foreground' : 'text-muted'
          "
          @click="$emit('navigate', page)"
        >
          <AppIcon
            :name="page.icon"
            class="size-4 shrink-0"
            :class="current === page.id ? 'text-primary' : 'text-muted'"
          />
          {{ page.label }}
          <span
            v-if="current === page.id"
            aria-hidden="true"
            class="ml-auto size-1 rounded-full bg-primary"
          />
        </button>
      </div>
    </div>
  </nav>
</template>
