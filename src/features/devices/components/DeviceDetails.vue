<script setup lang="ts">
import type { DeviceInfo, DeviceSummary } from '../types'
import InfoSection from './InfoSection.vue'
import UiIcon from '../../../components/UiIcon.vue'

defineProps<{ info: DeviceInfo; device: DeviceSummary }>()
</script>

<template>
  <div class="space-y-7">
    <dl
      class="grid grid-cols-1 divide-y divide-line overflow-hidden rounded-lg border border-line bg-raised/25 sm:grid-cols-3 sm:divide-x sm:divide-y-0"
    >
      <div class="px-4 py-3.5">
        <dt class="mb-1.5 flex items-center gap-1.5 text-[11px] text-muted">
          <UiIcon name="system" :size="13" />Version Android
        </dt>
        <dd class="text-sm font-medium">
          {{ info.androidVersion ?? 'Non disponible'
          }}<span v-if="info.apiLevel" class="ml-2 font-normal text-xs text-secondary"
            >API {{ info.apiLevel }}</span
          >
        </dd>
      </div>
      <div class="px-4 py-3.5">
        <dt class="mb-1.5 flex items-center gap-1.5 text-[11px] text-muted">
          <UiIcon name="shield" :size="13" />Correctif de sécurité
        </dt>
        <dd class="text-sm font-medium tabular-nums">
          {{ info.securityPatch ?? 'Non disponible' }}
        </dd>
      </div>
      <div class="min-w-0 px-4 py-3.5">
        <dt class="mb-1.5 flex items-center gap-1.5 text-[11px] text-muted">
          <UiIcon name="cpu" :size="13" />Processeur
        </dt>
        <dd class="break-words text-sm font-medium">
          {{ info.soc ?? info.hardware ?? 'Non disponible' }}
        </dd>
      </div>
    </dl>
    <div class="grid gap-x-10 gap-y-7 lg:grid-cols-2">
      <InfoSection
        title="Identité"
        icon="phone"
        :entries="[
          { label: 'Fabricant', value: info.manufacturer },
          { label: 'Marque', value: info.brand },
          { label: 'Modèle', value: info.model },
          { label: 'Nom de code', value: info.device },
          { label: 'Numéro de série', value: info.serial ?? device.serial },
        ]"
      />
      <InfoSection
        title="Android"
        icon="system"
        :entries="[
          { label: 'Version Android', value: info.androidVersion },
          { label: 'Niveau API', value: info.apiLevel },
          { label: 'Correctif de sécurité', value: info.securityPatch },
          { label: 'Build', value: info.buildId },
          { label: 'Bootloader', value: info.bootloader },
        ]"
      />
      <InfoSection
        title="Matériel"
        icon="cpu"
        :entries="[
          { label: 'Plateforme', value: info.hardware },
          { label: 'Processeur (SoC)', value: info.soc },
          { label: 'Architectures CPU', value: info.abis },
        ]"
      />
      <InfoSection
        title="Connexion USB"
        icon="cable"
        :entries="[
          { label: 'Transport', value: 'USB direct · adb_client' },
          { label: 'Bus : adresse', value: device.usbLocation },
          { label: 'Identifiant constructeur', value: device.vendorId },
          { label: 'Identifiant produit', value: device.productId },
        ]"
      />
    </div>
    <section class="border-t border-line pt-5">
      <h4 class="mb-3 flex items-center gap-2 text-xs font-medium">
        <UiIcon name="code" :size="14" class="text-muted" />Empreinte du build
      </h4>
      <p
        class="break-all rounded-md border border-line/70 bg-shell/40 px-3 py-2.5 font-mono text-[11px] leading-5 text-secondary"
      >
        {{ info.buildFingerprint ?? 'Non disponible' }}
      </p>
    </section>
    <p class="flex items-start gap-2 text-[11px] leading-5 text-muted">
      <UiIcon name="info" :size="13" class="mt-0.5" />Les informations disponibles dépendent du
      fabricant et de la version Android.
    </p>
  </div>
</template>
