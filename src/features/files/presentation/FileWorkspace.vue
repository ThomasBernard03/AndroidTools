<script setup lang="ts">
import { computed, onDeactivated, ref, watch } from 'vue';
import FileContextMenu from './FileContextMenu.vue';
import AppIcon from '../../../shared/presentation/widgets/AppIcon.vue';
import {
  childPath,
  validName,
  type FileEntry,
  type FileService,
  type Mutation,
} from '../domain/files';
import { useFiles } from './useFiles';

const props = defineProps<{
  deviceId: string | null;
  service?: FileService | undefined;
  demo?: boolean | undefined;
}>();
const {
  path,
  entries,
  loading,
  operating,
  error,
  operationError,
  message,
  writable,
  navigate,
  mutate,
  transfer,
} = useFiles(
  computed(() => props.deviceId),
  props.service,
);
const search = ref('');
const editing = ref<{ operation: Mutation; entry: FileEntry | null } | null>(
  null,
);
const name = ref('');
const busy = computed(() => loading.value || operating.value);
const context = ref<{ entry: FileEntry; x: number; y: number } | null>(null);
watch([path, () => props.deviceId, busy, search], () => {
  context.value = null;
});
onDeactivated(() => {
  context.value = null;
});
function openContext(event: MouseEvent | KeyboardEvent, entry: FileEntry) {
  if (busy.value) return;
  const row = event.currentTarget as HTMLElement;
  row.focus();
  const bounds = row.getBoundingClientRect();
  context.value = {
    entry,
    x:
      event instanceof MouseEvent && event.clientX
        ? event.clientX
        : bounds.left + 16,
    y:
      event instanceof MouseEvent && event.clientY
        ? event.clientY
        : bounds.bottom,
  };
}
function openEntry(entry: FileEntry) {
  if (!busy.value && entry.kind === 'directory')
    void navigate(childPath(path.value, entry.name));
}
function contextAction(action: 'open' | 'download' | 'rename' | 'delete') {
  const entry = context.value?.entry;
  context.value = null;
  if (!entry || busy.value) return;
  if (action === 'open') openEntry(entry);
  else if (actionable(entry)) {
    if (action === 'download')
      void transfer(false, entry.kind === 'directory', entry);
    else edit(action, entry);
  }
}
const visible = computed(() =>
  entries.value.filter((e) =>
    e.name.toLowerCase().includes(search.value.toLowerCase()),
  ),
);
const crumbs = computed(() => [
  { name: 'Android', path: '/' },
  ...path.value
    .split('/')
    .filter(Boolean)
    .map((name, index, parts) => ({
      name,
      path: `/${parts.slice(0, index + 1).join('/')}`,
    })),
]);
const locations = [
  { name: 'Shared storage', path: '/sdcard' },
  { name: 'Application data', path: '/data/data' },
  { name: 'Android root', path: '/' },
];
watch([path, () => props.deviceId], () => {
  editing.value = null;
  name.value = '';
  search.value = '';
});
function edit(operation: Mutation, entry: FileEntry | null = null) {
  editing.value = { operation, entry };
  name.value = operation === 'rename' ? (entry?.name ?? '') : '';
}
async function submit() {
  const selected = editing.value;
  if (
    selected &&
    (await mutate(selected.operation, selected.entry, name.value))
  )
    editing.value = null;
}
function actionable(entry: FileEntry) {
  return (
    writable.value &&
    ['file', 'directory'].includes(entry.kind) &&
    !['/sdcard', '/data', '/storage', '/data/user'].includes(
      childPath(path.value, entry.name),
    )
  );
}
function size(entry: FileEntry) {
  if (entry.kind === 'directory' || entry.size === null) return '—';
  if (entry.size < 1024) return `${entry.size} B`;
  if (entry.size < 1024 ** 2) return `${(entry.size / 1024).toFixed(1)} KiB`;
  return `${(entry.size / 1024 ** 2).toFixed(1)} MiB`;
}
function modified(value: number | null) {
  return value === null ? '—' : new Date(value * 1000).toLocaleString();
}
</script>

<template>
  <section
    class="mx-auto max-w-7xl space-y-5 px-6 py-8 lg:px-10"
    aria-labelledby="files-heading"
  >
    <div class="flex items-start justify-between gap-4">
      <div>
        <h2 id="files-heading" class="text-2xl font-semibold tracking-tight">
          File explorer
        </h2>
        <p class="mt-2 text-sm text-muted">
          Browse and manage files on the selected Android device.
        </p>
      </div>
      <button
        class="file-button"
        :disabled="!deviceId || busy"
        @click="navigate()"
      >
        Refresh
      </button>
    </div>
    <p
      v-if="!deviceId"
      class="rounded-xl border border-dashed border-stroke p-10 text-center text-muted"
    >
      Select a device and allow USB debugging to browse its files.
    </p>
    <template v-else>
      <nav aria-label="File locations" class="flex flex-wrap gap-2">
        <button
          v-for="location in locations"
          :key="location.path"
          class="file-button"
          :disabled="operating"
          :aria-current="path === location.path ? 'location' : undefined"
          @click="navigate(location.path)"
        >
          <AppIcon name="folder" class="size-4" />{{ location.name }}
        </button>
      </nav>
      <p
        class="rounded-lg border border-stroke bg-surface p-3 text-xs leading-5 text-muted"
      >
        <template v-if="path === '/data' || path.startsWith('/data/data')"
          >Application data uses <code>run-as</code> for the primary Android
          user. Installed packages are listed, but only debuggable apps allowing
          run-as can be opened.</template
        >
        <template v-else
          >Android permissions apply. Protected and read-only directories may be
          inaccessible. Symbolic links and special files are displayed without
          being opened.</template
        >
      </p>
      <div class="flex flex-wrap gap-2">
        <button
          class="file-button"
          :disabled="busy || !writable || !!error"
          @click="transfer(true, false)"
        >
          Upload file
        </button>
        <button
          class="file-button"
          :disabled="busy || !writable || !!error"
          @click="transfer(true, true)"
        >
          Upload folder
        </button>
        <button
          class="file-button"
          :disabled="busy || !writable || !!error"
          @click="edit('create_directory')"
        >
          New folder
        </button>
      </div>
      <form
        v-if="editing"
        class="space-y-3 rounded-lg border border-stroke bg-surface p-4"
        @submit.prevent="submit"
      >
        <template v-if="editing.operation === 'delete'">
          <p>
            Delete “{{ editing.entry?.name }}”{{
              editing.entry?.kind === 'directory' ? ' and all its contents' : ''
            }}
            permanently?
          </p>
          <p class="text-xs text-muted">This operation cannot be undone.</p>
        </template>
        <label v-else class="block text-sm"
          >{{ editing.operation === 'rename' ? 'New name' : 'Folder name' }}
          <input
            v-model="name"
            class="mt-2 block w-full rounded-lg border border-stroke bg-canvas px-3 py-2"
            :disabled="operating"
            required
          />
        </label>
        <div class="flex gap-2">
          <button
            class="file-button"
            :class="{ 'file-danger': editing.operation === 'delete' }"
            :disabled="
              busy ||
              (editing.operation !== 'delete' &&
                (!validName(name) ||
                  (editing.operation === 'rename' &&
                    name === editing.entry?.name)))
            "
          >
            {{
              editing.operation === 'delete'
                ? 'Confirm delete'
                : editing.operation === 'rename'
                  ? 'Save name'
                  : 'Create folder'
            }}
          </button>
          <button
            type="button"
            class="file-button"
            :disabled="operating"
            @click="editing = null"
          >
            Cancel
          </button>
        </div>
      </form>
      <div
        v-if="operationError"
        role="alert"
        class="rounded-lg border border-error/30 bg-error/5 p-4 text-sm text-error"
      >
        <p>{{ operationError.message }}</p>
        <p v-if="operationError.partial" class="mt-2">
          Some changes may already have been applied. Completed entries are
          kept; a failed upload can leave an incomplete file or folder. Refresh
          and inspect the destination before retrying.
        </p>
      </div>
      <p v-if="operating || message" role="status" class="text-sm text-primary">
        {{
          operating
            ? 'Operation in progress… Keep the device connected.'
            : `${demo ? 'Simulated: ' : ''}${message}`
        }}
      </p>
      <div
        class="overflow-hidden rounded-xl border border-stroke"
        :aria-busy="busy"
      >
        <div
          class="flex flex-wrap items-center gap-3 border-b border-stroke bg-surface p-3"
        >
          <button
            class="file-button"
            :disabled="path === '/' || operating"
            aria-label="Parent folder"
            @click="navigate(path.slice(0, path.lastIndexOf('/')) || '/')"
          >
            <AppIcon name="arrow-up" class="size-4" />
            Up
          </button>
          <nav aria-label="Folder path" class="min-w-0 flex-1">
            <ol class="flex flex-wrap items-center gap-1 text-xs">
              <li v-for="crumb in crumbs" :key="crumb.path">
                <button
                  class="rounded px-2 py-1 break-all hover:bg-primary/10"
                  :disabled="operating"
                  :aria-current="path === crumb.path ? 'location' : undefined"
                  @click="navigate(crumb.path)"
                >
                  {{ crumb.name }}</button
                ><span aria-hidden="true" class="text-muted">/</span>
              </li>
            </ol>
          </nav>
          <input
            v-model="search"
            type="search"
            aria-label="Search this folder"
            placeholder="Search this folder…"
            class="rounded-lg border border-stroke bg-canvas px-3 py-2 text-xs"
          />
        </div>
        <p v-if="loading" role="status" class="p-10 text-center text-muted">
          Reading directory…
        </p>
        <div v-else-if="error" class="space-y-3 p-5">
          <p role="alert" class="text-sm text-error">{{ error.message }}</p>
          <button class="file-button" @click="navigate()">Retry</button>
        </div>
        <p
          v-else-if="!visible.length"
          role="status"
          class="p-10 text-center text-muted"
        >
          {{
            entries.length ? 'No matching entries.' : 'This folder is empty.'
          }}
        </p>
        <div v-else class="overflow-x-auto">
          <table class="w-full text-left text-xs">
            <thead class="border-b border-stroke text-muted">
              <tr>
                <th scope="col" class="p-3">Name</th>
                <th scope="col" class="p-3">Size</th>
                <th scope="col" class="p-3">Modified</th>
                <th scope="col" class="p-3">Permissions</th>
                <th scope="col" class="p-3">Actions</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-stroke">
              <tr
                v-for="entry in visible"
                :key="entry.name"
                class="hover:bg-surface"
                tabindex="0"
                :aria-label="entry.name"
                @contextmenu.prevent="openContext($event, entry)"
                @keydown.shift.f10.prevent="openContext($event, entry)"
                @keydown.enter.self.prevent="openEntry(entry)"
                @dblclick="openEntry(entry)"
              >
                <td class="p-3">
                  <button
                    v-if="entry.kind === 'directory'"
                    class="flex items-center gap-2 text-left text-primary"
                    :disabled="operating"
                    @click="navigate(childPath(path, entry.name))"
                  >
                    <AppIcon name="folder" class="size-4 shrink-0" /><span
                      class="break-all whitespace-pre-wrap"
                      >{{ entry.name }}</span
                    ></button
                  ><span v-else class="break-all whitespace-pre-wrap"
                    >{{ entry.name
                    }}<span v-if="entry.kind !== 'file'" class="ml-2 text-muted"
                      >({{ entry.kind }})</span
                    ></span
                  >
                </td>
                <td class="p-3 whitespace-nowrap text-muted">
                  {{ size(entry) }}
                </td>
                <td class="p-3 whitespace-nowrap text-muted">
                  {{ modified(entry.modifiedAt) }}
                </td>
                <td class="p-3 font-mono text-muted">
                  {{ entry.permissions ?? '—' }}
                </td>
                <td class="p-3">
                  <div v-if="actionable(entry)" class="flex gap-2">
                    <button
                      class="file-button"
                      :disabled="busy"
                      :aria-label="`Download ${entry.name}`"
                      @dblclick.stop
                      @click="
                        transfer(false, entry.kind === 'directory', entry)
                      "
                    >
                      <AppIcon name="download" class="size-4" />Download</button
                    ><button
                      class="file-button"
                      :disabled="busy"
                      :aria-label="`Rename ${entry.name}`"
                      @dblclick.stop
                      @click="edit('rename', entry)"
                    >
                      <AppIcon name="rename" class="size-4" />Rename</button
                    ><button
                      class="file-button file-danger"
                      :disabled="busy"
                      :aria-label="`Delete ${entry.name}`"
                      @dblclick.stop
                      @click="edit('delete', entry)"
                    >
                      <AppIcon name="trash" class="size-4" />Delete
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <p
          v-if="!loading && !error"
          class="border-t border-stroke p-3 text-xs text-muted"
        >
          {{ entries.length }} entries · {{ path }}
        </p>
      </div>
    </template>
    <FileContextMenu
      v-if="context"
      :key="context.entry.name + ':' + context.x + ':' + context.y"
      :entry="context.entry"
      :actionable="actionable(context.entry)"
      :x="context.x"
      :y="context.y"
      @action="contextAction"
      @close="context = null"
    />
  </section>
</template>

<style scoped>
@reference '../../../styles.css';
.file-button {
  @apply inline-flex items-center justify-center gap-2 rounded-lg border border-stroke bg-surface px-3 py-2 text-xs font-medium hover:border-primary/40 hover:text-primary disabled:cursor-not-allowed disabled:opacity-40;
}
.file-button[aria-current='location'] {
  @apply border-primary/40 text-primary;
}
.file-button.file-danger {
  @apply text-danger hover:border-danger/40 hover:text-danger;
}
</style>
