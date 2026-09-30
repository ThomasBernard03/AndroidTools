<script setup lang="ts">
import { computed, ref } from 'vue'
import type { ApkPermission } from '../types'

const props = defineProps<{ permissions: ApkPermission[] }>()
const query = ref('')
const filtered = computed(() =>
  props.permissions.filter((permission) =>
    permission.name.toLowerCase().includes(query.value.trim().toLowerCase()),
  ),
)
const labels = {
  requested: 'Demandée',
  requestedSdk23: 'Demandée · API ≥ 23',
  declared: 'Définie par l’application',
}
</script>

<template>
  <section aria-label="Permissions APK" class="space-y-4">
    <p class="text-xs leading-5 text-secondary">
      Permissions demandées et permissions définies dans le manifeste. Cette liste ne décrit pas les
      autorisations accordées sur un téléphone.
    </p>
    <label for="permission-search" class="sr-only">Rechercher une permission</label>
    <input
      id="permission-search"
      v-model="query"
      type="search"
      placeholder="Rechercher une permission…"
      class="w-full rounded-md border border-line bg-shell/40 px-3 py-2 text-xs"
    />
    <p role="status" class="text-xs text-muted">
      {{ filtered.length }} / {{ permissions.length }} permission(s)
    </p>
    <div class="overflow-x-auto rounded-lg border border-line">
      <table v-if="filtered.length" class="w-full text-left text-xs">
        <thead class="border-b border-line bg-raised text-secondary">
          <tr>
            <th scope="col" class="px-4 py-3 font-medium">Permission</th>
            <th scope="col" class="px-4 py-3 font-medium">Déclaration</th>
            <th scope="col" class="px-4 py-3 font-medium">Contraintes</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-line/60">
          <tr v-for="(permission, index) in filtered" :key="index" class="hover:bg-raised/40">
            <td class="min-w-48 break-all px-4 py-3 font-mono text-[11px]">
              {{ permission.name }}
            </td>
            <td class="px-4 py-3 text-secondary">{{ labels[permission.kind] }}</td>
            <td class="px-4 py-3 text-secondary">
              <p v-if="permission.maxSdk">API max. {{ permission.maxSdk }}</p>
              <p v-if="permission.protectionLevel" class="break-all">
                Protection : {{ permission.protectionLevel }}
              </p>
              <span v-if="!permission.maxSdk && !permission.protectionLevel">—</span>
            </td>
          </tr>
        </tbody>
      </table>
      <p v-else class="p-6 text-center text-secondary">
        {{
          permissions.length
            ? 'Aucune permission ne correspond à la recherche.'
            : 'Aucune permission déclarée dans ce manifeste.'
        }}
      </p>
    </div>
  </section>
</template>
