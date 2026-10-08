<script setup lang="ts">
import { workspacePages, type WorkspacePage } from '../workspaceNavigation';
import AppIcon from './AppIcon.vue';

defineProps<{ current: WorkspacePage['id'] }>();
defineEmits<{ navigate: [page: WorkspacePage] }>();
</script>

<template>
  <nav aria-label="Workspace" class="flex flex-1 flex-col gap-4 px-3 pt-4">
    <div
      v-for="group in ['Device', 'APK & Keystore', 'Application']"
      :key="group"
      class="xp-navigation-group"
      :class="group === 'Application' ? 'mt-auto' : ''"
    >
      <p class="xp-task-heading">
        {{ group }}
      </p>
      <div class="xp-navigation-items space-y-1">
        <button
          v-for="page in workspacePages.filter(
            (entry) => entry.group === group,
          )"
          :key="page.id"
          type="button"
          :aria-current="current === page.id ? 'page' : undefined"
          class="xp-navigation-button flex w-full items-center gap-2.5 px-2.5 py-2 text-left text-[13px] font-medium"
          @click="$emit('navigate', page)"
        >
          <AppIcon :name="page.icon" class="size-4 shrink-0" />
          {{ page.label }}
        </button>
      </div>
    </div>
  </nav>
</template>
