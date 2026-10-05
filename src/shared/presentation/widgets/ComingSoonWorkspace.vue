<script setup lang="ts">
import type { WorkspacePage } from '../workspaceNavigation';
import AppIcon from './AppIcon.vue';

defineProps<{ page: WorkspacePage }>();
</script>

<template>
  <section
    aria-labelledby="coming-soon-title"
    class="mx-auto w-full max-w-5xl px-6 py-10 lg:px-10"
  >
    <p class="mb-2 text-xs font-medium tracking-widest text-muted uppercase">
      {{ page.group }}
    </p>
    <h2 id="coming-soon-title" class="text-2xl font-semibold tracking-tight">
      {{ page.label }}
    </h2>
    <p class="mt-2 text-sm text-muted">{{ page.description }}</p>
    <div
      class="mt-8 flex flex-col items-center rounded-xl border border-stroke bg-surface px-6 py-16 text-center"
    >
      <div
        class="mb-5 rounded-xl border border-primary/15 bg-primary/8 p-4 text-primary"
      >
        <AppIcon :name="page.icon" class="size-7" />
      </div>
      <h3 class="text-base font-semibold">Coming soon</h3>
      <p class="mt-2 max-w-sm text-sm leading-6 text-muted">
        This tool is not available yet. Its functionality will be added in a
        future update.
      </p>
    </div>
  </section>
</template>
