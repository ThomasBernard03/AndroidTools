<script setup lang="ts">
import { toRef } from 'vue'
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
  filteredEntries,
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
            >Exploration en lecture seule. Ouvrez un dossier pour naviguer ou un fichier pour
            afficher son aperçu texte.</template
          >
        </div>
      </div>

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
          />
        </div>

        <div v-if="loading" role="status" class="py-16 text-center text-secondary">
          <UiIcon name="refresh" :size="22" class="mx-auto mb-3 animate-spin text-accent" />Lecture
          du dossier…
        </div>
        <div v-else-if="error" class="space-y-4 p-5">
          <ErrorNotice :error="error" />
          <button type="button" class="button" @click="refresh">Réessayer</button>
        </div>
        <p
          v-else-if="!filteredEntries.length"
          role="status"
          class="px-5 py-16 text-center text-secondary"
        >
          {{
            search.trim()
              ? 'Aucun élément ne correspond à votre recherche.'
              : 'Ce dossier est vide.'
          }}
        </p>
        <div v-else class="overflow-x-auto">
          <table class="w-full text-left text-xs">
            <thead class="border-b border-line text-[11px] text-muted">
              <tr>
                <th scope="col" class="px-4 py-2.5 font-medium">Nom</th>
                <th scope="col" class="px-4 py-2.5 font-medium">Taille</th>
                <th scope="col" class="px-4 py-2.5 font-medium">Modification</th>
                <th scope="col" class="px-4 py-2.5 font-medium">Droits</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-line/60">
              <tr
                v-for="entry in filteredEntries"
                :key="entry.name"
                class="hover:bg-raised/50"
                :class="{ 'bg-accent/5': selectedEntry?.name === entry.name }"
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
              </tr>
            </tbody>
          </table>
        </div>
        <footer
          v-if="!loading && !error"
          class="border-t border-line px-4 py-2 text-[11px] text-muted"
        >
          {{ filteredEntries.length }} / {{ entries.length }} élément{{
            entries.length > 1 ? 's' : ''
          }}
          · Lecture seule
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
