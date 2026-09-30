<script setup lang="ts">
import type { ApkSignature } from '../types'
import UiIcon from '../../../components/UiIcon.vue'

defineProps<{ signatures: ApkSignature[]; warnings: string[] }>()
</script>

<template>
  <section aria-label="Signatures APK" class="space-y-5">
    <p class="flex items-start gap-2 text-xs leading-5 text-secondary">
      <UiIcon name="info" class="mt-0.5" />Certificats extraits de l’APK. La validité
      cryptographique et l’intégrité de la signature ne sont pas vérifiées. Le schéma v4 (fichier
      .idsig séparé) n’est pas analysé.
    </p>
    <p
      v-for="warning in warnings"
      :key="warning"
      role="alert"
      class="rounded-md border border-amber-300/15 bg-amber-200/4 p-3 text-xs text-amber-200"
    >
      {{ warning }}
    </p>
    <p
      v-if="!signatures.length"
      class="rounded-lg border border-line p-6 text-center text-secondary"
    >
      {{
        warnings.length
          ? 'Les signatures n’ont pas pu être entièrement lues.'
          : 'Aucun certificat de signature reconnu dans cet APK.'
      }}
    </p>
    <section v-for="(signature, schemeIndex) in signatures" :key="schemeIndex" class="space-y-4">
      <h3 class="flex items-center gap-2 text-sm font-medium">
        <UiIcon name="shield" class="text-accent" />Schéma {{ signature.scheme
        }}<span class="status-badge">{{ signature.certificates.length }} certificat(s)</span>
      </h3>
      <p v-if="!signature.certificates.length" class="text-xs text-secondary">
        Bloc présent, mais aucun certificat lisible.
      </p>
      <div
        v-for="(certificate, index) in signature.certificates"
        :key="index"
        class="rounded-lg border border-line bg-raised/25 p-4"
      >
        <h4 class="mb-3 text-xs font-medium text-accent">Certificat {{ index + 1 }}</h4>
        <dl class="space-y-3 text-xs">
          <div
            v-for="entry in [
              { label: 'Sujet', value: certificate.subject },
              { label: 'Émetteur', value: certificate.issuer },
              { label: 'Numéro de série', value: certificate.serialNumber },
              { label: 'Valide à partir du', value: certificate.validFrom },
              { label: 'Valide jusqu’au', value: certificate.validUntil },
              { label: 'Algorithme du certificat', value: certificate.algorithm },
              { label: 'Empreinte SHA-256', value: certificate.sha256 },
              { label: 'Empreinte SHA-1', value: certificate.sha1 },
            ]"
            :key="entry.label"
            class="grid gap-1 sm:grid-cols-[160px_minmax(0,1fr)] sm:gap-4"
          >
            <dt class="text-secondary">{{ entry.label }}</dt>
            <dd class="break-all font-mono text-[11px] leading-5">
              {{ entry.value || 'Non disponible' }}
            </dd>
          </div>
        </dl>
      </div>
    </section>
  </section>
</template>
