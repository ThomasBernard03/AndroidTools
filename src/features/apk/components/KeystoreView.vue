<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import ErrorNotice from '../../../components/ErrorNotice.vue'
import UiIcon from '../../../components/UiIcon.vue'
import { chooseToolOutput, generateKeystore } from '../api'
import { useApkOperation } from '../useApkOperation'

const emit = defineEmits<{ generated: [path: string, alias: string] }>()
const form = reactive({
  alias: 'release',
  password: '',
  commonName: '',
  organization: '',
  country: '',
  validityDays: 10000,
})
const confirmation = ref('')
const passwordVisible = ref(false)
const copyStatus = ref('')
watch(
  () => form.password,
  () => {
    copyStatus.value = ''
  },
)

async function copyPassword() {
  const password = form.password
  if (!password) return
  try {
    await navigator.clipboard.writeText(password)
    if (form.password === password) copyStatus.value = 'Mot de passe copié.'
  } catch {
    if (form.password === password) copyStatus.value = 'Impossible de copier le mot de passe.'
  }
}

const { busy, error, result, run } = useApkOperation()
const validity = computed(() => {
  const days = form.validityDays
  if (!Number.isInteger(days) || days < 1 || days > 36500) return null
  const expiration = new Date(Date.now() + days * 86400000)
  const years = Math.round((days / 365.25) * 10) / 10
  return {
    duration: `${days.toLocaleString('fr-FR')} ${days === 1 ? 'jour' : 'jours'} (environ ${years.toLocaleString('fr-FR')} ${years < 2 ? 'an' : 'ans'})`,
    expiration: expiration.toLocaleDateString('fr-FR', {
      day: 'numeric',
      month: 'long',
      year: 'numeric',
    }),
  }
})

function generatePassword() {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_'
  const bytes = crypto.getRandomValues(new Uint8Array(24))
  form.password = Array.from(bytes, (byte) => alphabet[byte & 63]).join('')
  confirmation.value = form.password
}

async function submit() {
  if (form.password !== confirmation.value) return
  await run(
    async () => {
      const outputPath = await chooseToolOutput('keystore')
      if (!outputPath) return null
      const path = await generateKeystore({ ...form, outputPath })
      emit('generated', path, form.alias)
      return path
    },
    () => {
      form.password = ''
      confirmation.value = ''
      passwordVisible.value = false
    },
  )
}
</script>

<template>
  <form class="space-y-5" :aria-busy="busy" @submit.prevent="submit">
    <p class="text-secondary">
      Créez une clé RSA 3072 bits dans un keystore PKCS#12 (.p12). Le mot de passe protège à la fois
      le keystore et la clé.
    </p>
    <fieldset :disabled="busy" class="grid gap-5 sm:grid-cols-2">
      <label class="space-y-2"
        ><span class="block text-secondary">Alias de la clé</span
        ><input v-model="form.alias" class="form-input w-full" required
      /></label>
      <label class="space-y-2"
        ><span class="block text-secondary">Validité (jours)</span
        ><input
          v-model.number="form.validityDays"
          type="number"
          min="1"
          max="36500"
          step="1"
          class="form-input w-full"
          required
          aria-describedby="keystore-validity"
        />
        <span
          v-if="validity"
          id="keystore-validity"
          class="block text-xs text-muted"
          aria-live="polite"
        >
          <span class="block">{{ validity.duration }}</span>
          <span class="block">Expiration : {{ validity.expiration }}</span>
        </span>
      </label>
      <label class="space-y-2 sm:col-span-2"
        ><span class="block text-secondary">Nom du certificat (CN)</span
        ><input
          v-model="form.commonName"
          class="form-input w-full"
          placeholder="Mon application"
          required
      /></label>
      <label class="space-y-2"
        ><span class="block text-secondary">Organisation (facultatif)</span
        ><input v-model="form.organization" class="form-input w-full" placeholder="Mon entreprise"
      /></label>
      <label class="space-y-2"
        ><span class="block text-secondary">Code pays (facultatif)</span
        ><input
          v-model="form.country"
          class="form-input w-full"
          placeholder="FR"
          pattern="[a-zA-Z]{2}"
          maxlength="2"
      /></label>
      <div class="min-w-0 space-y-2">
        <label for="keystore-password" class="block text-secondary">Mot de passe</label>
        <div class="relative">
          <input
            id="keystore-password"
            v-model="form.password"
            :type="passwordVisible ? 'text' : 'password'"
            autocomplete="new-password"
            minlength="6"
            class="form-input w-full pr-28"
            required
          />
          <div class="absolute inset-y-0 right-2 flex items-center gap-1">
            <button
              type="button"
              class="icon-button"
              :title="passwordVisible ? 'Masquer le mot de passe' : 'Afficher le mot de passe'"
              :aria-label="passwordVisible ? 'Masquer le mot de passe' : 'Afficher le mot de passe'"
              :aria-pressed="passwordVisible"
              @click="passwordVisible = !passwordVisible"
            >
              <UiIcon :name="passwordVisible ? 'eyeOff' : 'eye'" />
            </button>
            <button
              type="button"
              class="icon-button disabled:opacity-50"
              title="Copier le mot de passe"
              aria-label="Copier le mot de passe"
              :disabled="!form.password"
              @click="copyPassword"
            >
              <UiIcon name="copy" />
            </button>
            <button
              type="button"
              class="icon-button"
              title="Générer un mot de passe"
              @click="generatePassword"
            >
              <UiIcon name="refresh" /><span class="sr-only">Générer un mot de passe</span>
            </button>
          </div>
        </div>
        <p v-if="copyStatus" role="status" class="text-xs text-muted">{{ copyStatus }}</p>
      </div>
      <label class="space-y-2"
        ><span class="block text-secondary">Confirmer le mot de passe</span
        ><input
          v-model="confirmation"
          type="password"
          autocomplete="new-password"
          minlength="6"
          class="form-input w-full"
          required
      /></label>
    </fieldset>
    <p v-if="confirmation && confirmation !== form.password" role="status" class="text-amber-200">
      Les mots de passe ne correspondent pas.
    </p>
    <p class="text-xs text-muted">
      Conservez le keystore, son alias et son mot de passe pour les prochaines mises à jour de votre
      application. Un fichier .p12.json contenant les informations du keystore et le mot de passe en
      clair sera enregistré à côté du keystore. Conservez ces deux fichiers en lieu sûr.
    </p>
    <button
      type="submit"
      class="button"
      :disabled="busy || !form.password || form.password !== confirmation"
    >
      {{ busy ? 'Génération en cours…' : 'Générer le keystore…' }}
    </button>
    <ErrorNotice v-if="error" :error="error" />
    <div v-if="result" role="status" class="rounded-lg border border-positive/30 p-4 text-positive">
      <p>Keystore généré avec succès.</p>
      <p class="mt-2 break-all font-mono text-xs">{{ result }}</p>
      <p class="mt-2">Informations et mot de passe enregistrés :</p>
      <p class="mt-2 break-all font-mono text-xs">{{ result }}.json</p>
    </div>
  </form>
</template>
