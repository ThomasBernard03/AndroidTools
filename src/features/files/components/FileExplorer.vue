<script setup lang="ts">
import { ref, toRef, watch } from 'vue'
import type { FileEntry } from '../types'
import UiIcon from '../../../components/UiIcon.vue'
import ErrorNotice from '../../../components/ErrorNotice.vue'
import FilePreview from './FilePreview.vue'
import { useFiles } from '../useFiles'
import { formatDate, formatSize } from '../format'

const props = defineProps<{ deviceId: string }>()
const {
  path,
  entries,
  search,
  matches,
  matchIndex,
  activeMatch,
  moveMatch,
  operating,
  operationError,
  operationMessage,
  writable,
  download,
  upload,
  mkdir,
  remove,
  breadcrumbs,
  privatePackage,
  error,
  loading,
  selectedEntry,
  preview,
  previewError,
  loadingPreview,
  navigate,
  parent,
  refresh,
  openEntry,
  closePreview,
} = useFiles(toRef(props, 'deviceId'))

const table = ref<HTMLElement | null>(null)
const folderName = ref('')
const creatingFolder = ref(false)
const deleting = ref<FileEntry | null>(null)
watch([path, () => props.deviceId], () => {
  creatingFolder.value = false
  folderName.value = ''
  deleting.value = null
})
watch(
  [activeMatch, search],
  ([name]) => {
    if (name) {
      const row = Array.from(table.value?.querySelectorAll<HTMLElement>('[data-name]') ?? []).find(
        (row) => row.dataset.name === name,
      )
      row?.scrollIntoView?.({ block: 'nearest', behavior: 'smooth' })
    }
  },
  { flush: 'post' },
)
async function submitFolder() {
  if (await mkdir(folderName.value)) {
    creatingFolder.value = false
    folderName.value = ''
  }
}
async function confirmDelete() {
  if (deleting.value && (await remove(deleting.value))) deleting.value = null
}

const locations = [
  { name: 'Stockage partagé', path: '/sdcard', icon: 'folder' },
  { name: 'Données des applications', path: '/data/data', icon: 'package' },
  { name: 'Racine Android', path: '/', icon: 'system' },
] as const
const kinds = {
  directory: 'Dossier',
  file: 'Fichier',
  symlink: 'Lien symbolique',
  other: 'Fichier spécial',
}
</script>

<template>
  <div class="mx-auto flex w-full max-w-6xl flex-1 flex-col px-6 py-8 lg:px-10 lg:py-10">
    <div class="mb-7 flex flex-wrap items-start justify-between gap-4">
      <div>
        <p class="section-label mb-2">APPAREILS / FICHIERS</p>
        <h2 class="text-[23px] font-semibold leading-8 tracking-[-0.035em]">
          Explorateur de fichiers
        </h2>
        <p class="mt-1.5 text-[13px] text-secondary">
          Parcourez le stockage et les données privées de vos applications debuggables.
        </p>
      </div>
      <button
        v-if="deviceId"
        type="button"
        class="button mt-1"
        :disabled="loading"
        @click="refresh"
      >
        <UiIcon name="refresh" :size="13" :class="{ 'animate-spin': loading }" />Actualiser
      </button>
    </div>

    <div
      v-if="!deviceId"
      class="rounded-lg border border-dashed border-line px-6 py-16 text-center"
    >
      <UiIcon name="folder" :size="32" class="mx-auto mb-4 text-accent" />
      <h3 class="font-medium">Sélectionnez un appareil</h3>
      <p class="mx-auto mt-2 max-w-sm text-xs leading-5 text-secondary">
        Connectez votre téléphone en USB, autorisez le débogage puis sélectionnez-le dans la barre
        latérale.
      </p>
    </div>

    <template v-else>
      <nav aria-label="Emplacements favoris" class="mb-5 flex flex-wrap gap-2">
        <button
          v-for="location in locations"
          :key="location.path"
          type="button"
          class="button"
          :class="{ 'border-accent/40 text-accent': path === location.path }"
          :aria-current="path === location.path ? 'location' : undefined"
          @click="navigate(location.path)"
        >
          <UiIcon :name="location.icon" :size="14" />{{ location.name }}
        </button>
      </nav>

      <div class="mb-5 flex items-start gap-3 rounded-lg border border-line bg-raised/35 px-4 py-3">
        <UiIcon :name="privatePackage ? 'shield' : 'info'" class="mt-0.5 text-accent" />
        <div class="min-w-0 text-xs leading-5 text-secondary">
          <template v-if="privatePackage">
            <p class="break-all font-medium text-ink">{{ privatePackage }}</p>
            <p>Navigation privée via run-as · Utilisateur Android principal</p>
          </template>
          <template v-else-if="path === '/data/data' || path === '/data'">
            Les packages installés sont listés ici. Seules les applications debuggables autorisant
            <span class="font-mono">run-as</span> donnent accès à leurs données privées.
          </template>
          <template v-else
            >Ouvrez un dossier pour naviguer ou un fichier pour afficher son aperçu texte.</template
          >
        </div>
      </div>

      <div class="mb-4 flex flex-wrap gap-2">
        <button
          class="button"
          :disabled="loading || operating || !writable || !!error"
          @click="upload(false)"
        >
          Envoyer un fichier
        </button>
        <button
          class="button"
          :disabled="loading || operating || !writable || !!error"
          @click="upload(true)"
        >
          Envoyer un dossier
        </button>
        <button
          class="button"
          :disabled="loading || operating || !writable || !!error"
          @click="creatingFolder = !creatingFolder"
        >
          Nouveau dossier
        </button>
      </div>
      <form v-if="creatingFolder" class="mb-4 flex gap-2" @submit.prevent="submitFolder">
        <input
          v-model="folderName"
          aria-label="Nom du nouveau dossier"
          required
          pattern="[^/]+"
          class="rounded-md border border-line bg-surface px-3 py-1.5 text-xs"
          :disabled="operating"
        />
        <button
          class="button"
          :disabled="operating || !folderName || folderName === '.' || folderName === '..'"
        >
          Créer
        </button>
        <button type="button" class="button" :disabled="operating" @click="creatingFolder = false">
          Annuler
        </button>
      </form>
      <div v-if="deleting" class="mb-4 rounded-lg border border-line p-4" role="alert">
        <p class="mb-3 text-xs">
          Supprimer « {{ deleting.name }} »{{
            deleting.kind === 'directory' ? ' et tout son contenu' : ''
          }}
          ?
        </p>
        <div class="flex gap-2">
          <button class="button" :disabled="operating" @click="confirmDelete">
            Confirmer la suppression
          </button>
          <button class="button" :disabled="operating" @click="deleting = null">Annuler</button>
        </div>
      </div>
      <ErrorNotice v-if="operationError" :error="operationError" class="mb-4" />
      <p v-if="operating || operationMessage" role="status" class="mb-4 text-xs text-secondary">
        {{ operating ? 'Opération en cours…' : operationMessage }}
      </p>

      <section
        aria-label="Fichiers du dossier"
        :aria-busy="loading"
        class="overflow-hidden rounded-lg border border-line"
      >
        <div class="flex flex-wrap items-center gap-3 border-b border-line bg-raised/35 p-3">
          <button
            type="button"
            class="icon-button"
            :disabled="path === '/'"
            aria-label="Dossier parent"
            @click="parent"
          >
            <UiIcon name="up" />
          </button>
          <nav aria-label="Chemin du dossier" class="min-w-0 flex-1">
            <ol class="flex flex-wrap items-center gap-1 text-xs">
              <li
                v-for="(crumb, index) in breadcrumbs"
                :key="crumb.path"
                class="flex min-w-0 items-center gap-1"
              >
                <UiIcon v-if="index" name="chevron" :size="12" class="text-muted" />
                <button
                  type="button"
                  class="break-all rounded px-1.5 py-1 hover:bg-hover"
                  :class="index === breadcrumbs.length - 1 ? 'text-ink' : 'text-muted'"
                  :aria-current="index === breadcrumbs.length - 1 ? 'location' : undefined"
                  @click="navigate(crumb.path)"
                >
                  {{ crumb.name }}
                </button>
              </li>
            </ol>
          </nav>
          <input
            v-model="search"
            type="search"
            aria-label="Rechercher dans ce dossier"
            placeholder="Rechercher dans ce dossier…"
            class="min-w-0 rounded-md border border-line bg-surface px-3 py-1.5 text-xs placeholder:text-muted"
            @keydown.enter.prevent="moveMatch($event.shiftKey ? -1 : 1)"
          />
          <template v-if="search.trim()">
            <span role="status" class="text-xs text-secondary">{{
              matches.length
                ? `${matchIndex + 1} / ${matches.length}`
                : 'Aucun élément ne correspond à votre recherche.'
            }}</span>
            <button
              class="button"
              :disabled="!matches.length"
              aria-label="Correspondance précédente"
              @click="moveMatch(-1)"
            >
              Précédent
            </button>
            <button
              class="button"
              :disabled="!matches.length"
              aria-label="Correspondance suivante"
              @click="moveMatch(1)"
            >
              Suivant
            </button>
          </template>
        </div>

        <div v-if="loading" role="status" class="py-16 text-center text-secondary">
          <UiIcon name="refresh" :size="22" class="mx-auto mb-3 animate-spin text-accent" />Lecture
          du dossier…
        </div>
        <div v-else-if="error" class="space-y-4 p-5">
          <ErrorNotice :error="error" />
          <button type="button" class="button" @click="refresh">Réessayer</button>
        </div>
        <p v-else-if="!entries.length" role="status" class="px-5 py-16 text-center text-secondary">
          Ce dossier est vide.
        </p>
        <div v-else ref="table" class="max-h-[60vh] overflow-auto">
          <table class="w-full text-left text-xs">
            <thead class="border-b border-line text-[11px] text-muted">
              <tr>
                <th scope="col" class="px-4 py-2.5 font-medium">Nom</th>
                <th scope="col" class="px-4 py-2.5 font-medium">Taille</th>
                <th scope="col" class="px-4 py-2.5 font-medium">Modification</th>
                <th scope="col" class="px-4 py-2.5 font-medium">Droits</th>
                <th scope="col" class="px-4 py-2.5 font-medium">Actions</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-line/60">
              <tr
                v-for="entry in entries"
                :key="entry.name"
                :data-name="entry.name"
                class="hover:bg-raised/50"
                :class="{
                  'bg-accent/5': selectedEntry?.name === entry.name,
                  'bg-accent/15 outline outline-accent/40 -outline-offset-1':
                    activeMatch === entry.name,
                }"
              >
                <td class="px-4 py-2.5">
                  <button
                    type="button"
                    class="flex w-full items-center gap-3 text-left disabled:opacity-60"
                    :disabled="entry.kind === 'symlink' || entry.kind === 'other'"
                    :title="kinds[entry.kind]"
                    @click="openEntry(entry)"
                  >
                    <UiIcon
                      :name="
                        entry.kind === 'directory'
                          ? 'folder'
                          : entry.kind === 'symlink'
                            ? 'link'
                            : 'file'
                      "
                      :size="19"
                      :class="entry.kind === 'directory' ? 'text-accent' : 'text-muted'"
                    />
                    <span class="max-w-md break-all whitespace-pre-wrap">{{ entry.name }}</span>
                    <span class="sr-only"> · {{ kinds[entry.kind] }}</span>
                  </button>
                </td>
                <td class="whitespace-nowrap px-4 py-2.5 text-secondary">
                  {{ entry.kind === 'directory' ? '—' : formatSize(entry.size) }}
                </td>
                <td class="whitespace-nowrap px-4 py-2.5 text-secondary">
                  {{ formatDate(entry.modifiedAt) }}
                </td>
                <td class="px-4 py-2.5 font-mono text-muted">{{ entry.permissions ?? '—' }}</td>
                <td class="px-4 py-2.5">
                  <div
                    v-if="writable && (entry.kind === 'file' || entry.kind === 'directory')"
                    class="flex gap-2"
                  >
                    <button
                      class="button"
                      :disabled="operating"
                      :aria-label="`Télécharger ${entry.name}`"
                      @click="download(entry)"
                    >
                      Télécharger
                    </button>
                    <button
                      class="button"
                      :disabled="operating"
                      :aria-label="`Supprimer ${entry.name}`"
                      @click="deleting = entry"
                    >
                      Supprimer
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <footer
          v-if="!loading && !error"
          class="border-t border-line px-4 py-2 text-[11px] text-muted"
        >
          {{ entries.length }} élément{{ entries.length > 1 ? 's' : '' }}
        </footer>
      </section>

      <FilePreview
        v-if="selectedEntry"
        class="mt-5"
        :entry="selectedEntry"
        :preview="preview"
        :loading="loadingPreview"
        :error="previewError"
        @close="closePreview"
        @retry="openEntry(selectedEntry)"
      />
      <p class="mt-4 text-[11px] text-muted">
        Les liens symboliques et fichiers spéciaux sont affichés sans être ouverts.
      </p>
    </template>
  </div>
</template>
