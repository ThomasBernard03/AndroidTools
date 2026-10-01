<script setup lang="ts">
import { ref } from 'vue'
import KeystoreView from './KeystoreView.vue'
import SignApkView from './SignApkView.vue'

defineProps<{ mode: 'keystore' | 'sign' }>()
const generated = ref<{ path: string; alias: string } | null>(null)
</script>

<template>
  <div class="mx-auto w-full max-w-5xl space-y-6 px-6 py-8 lg:px-10 lg:py-10">
    <header>
      <p class="section-label mb-2">APK / {{ mode === 'keystore' ? 'CLÉS' : 'SIGNATURE' }}</p>
      <h2 class="text-[23px] font-semibold leading-8 tracking-[-0.035em]">
        {{ mode === 'keystore' ? 'Génération de keystore' : 'Signature d’APK' }}
      </h2>
      <p class="mt-2 text-secondary">
        Traitement local intégré à l’application. Aucun JDK ni SDK Android nécessaire.
      </p>
    </header>
    <KeystoreView
      v-show="mode === 'keystore'"
      @generated="(path, alias) => (generated = { path, alias })"
    />
    <SignApkView v-show="mode === 'sign'" :generated-keystore="generated" />
  </div>
</template>
