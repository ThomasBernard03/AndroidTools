<script setup lang="ts">
import UiIcon from '../../../components/UiIcon.vue'

defineProps<{ hasDevices: boolean; scanned: boolean }>()
</script>

<template>
  <section
    class="flex flex-1 flex-col items-center justify-center rounded-lg border border-line/70 px-5 py-12 text-center lg:py-16"
  >
    <div aria-hidden="true" class="relative mb-7 flex size-28 items-center justify-center">
      <div class="absolute inset-0 rounded-full border border-line/50"></div>
      <div class="absolute inset-3 rounded-full border border-line/80"></div>
      <div
        class="relative flex h-16 w-12 -rotate-6 items-center justify-center rounded-xl border border-[#45444f] bg-linear-to-b from-[#30303b] to-raised shadow-lg shadow-black/25"
      >
        <UiIcon name="phone" :size="33" class="text-secondary" />
      </div>
      <span
        class="absolute bottom-3 right-2 flex size-7 items-center justify-center rounded-lg border border-[#494461] bg-[#292538] text-accent"
        ><UiIcon :name="hasDevices ? 'check' : 'cable'" :size="15"
      /></span>
    </div>
    <h3 class="text-base font-medium tracking-tight">
      {{ hasDevices ? 'Choisissez votre appareil' : 'Connectez un appareil Android' }}
    </h3>
    <p v-if="!scanned" role="status" class="mt-2 text-xs text-secondary">
      Recherche des appareils USB…
    </p>
    <p v-else-if="hasDevices" class="mt-2 max-w-xs text-[13px] leading-6 text-secondary">
      Sélectionnez un appareil dans la barre latérale pour consulter ses informations.
    </p>
    <template v-else>
      <p class="mt-2 max-w-xs text-[13px] leading-6 text-secondary">
        Les informations de votre téléphone apparaîtront ici une fois la connexion établie.
      </p>
      <ol
        class="mt-8 w-full max-w-xs space-y-4 border-t border-line pt-6 text-left text-xs text-secondary"
      >
        <li class="flex items-center gap-3">
          <span
            class="flex size-5 shrink-0 items-center justify-center rounded-md border border-line font-mono text-[10px] text-muted"
            >1</span
          >Branchez un câble USB de données
        </li>
        <li class="flex items-center gap-3">
          <span
            class="flex size-5 shrink-0 items-center justify-center rounded-md border border-line font-mono text-[10px] text-muted"
            >2</span
          >Activez le débogage USB
        </li>
        <li class="flex items-center gap-3">
          <span
            class="flex size-5 shrink-0 items-center justify-center rounded-md border border-line font-mono text-[10px] text-muted"
            >3</span
          >Acceptez l’autorisation sur le téléphone
        </li>
      </ol>
    </template>
  </section>
</template>
