<script setup lang="ts">
import { reactive, watch } from 'vue'
import ErrorNotice from '../../../components/ErrorNotice.vue'
import ApkToolPath from './ApkToolPath.vue'
import { chooseToolOutput, signApk } from '../api'
import { useApkOperation } from '../useApkOperation'

const props = defineProps<{ generatedKeystore: { path: string; alias: string } | null }>()
const form = reactive({
  apkPath: '',
  keystorePath: '',
  alias: 'release',
  storePassword: '',
  keyPassword: '',
})
const { busy, error, result, run } = useApkOperation()
watch(
  () => props.generatedKeystore,
  (keystore) => {
    if (keystore && !busy.value) {
      form.keystorePath = keystore.path
      form.alias = keystore.alias
    }
  },
)
async function submit() {
  await run(
    async () => {
      const outputPath = await chooseToolOutput('apk')
      if (!outputPath) return null
      return signApk({ ...form, outputPath })
    },
    () => {
      form.storePassword = ''
      form.keyPassword = ''
    },
  )
}
</script>

<template>
  <form class="space-y-5" :aria-busy="busy" @submit.prevent="submit">
    <p class="text-secondary">
      Alignez et signez un APK en v2 (RSA / SHA-256), puis vérifiez sa signature et son intégrité.
      Le résultat est enregistré dans un nouveau fichier.
    </p>
    <p class="rounded-lg border border-accent/20 bg-accent/5 p-4 text-secondary">
      Compatible avec Android 7.0 et ultérieur (API 24+). Les anciennes signatures sont remplacées ;
      le manifeste et son SDK minimum ne sont pas modifiés.
    </p>
    <fieldset :disabled="busy" class="space-y-5">
      <ApkToolPath
        v-model="form.apkPath"
        label="APK à signer"
        :extensions="['apk']"
        :disabled="busy"
      />
      <ApkToolPath
        v-model="form.keystorePath"
        label="Keystore de signature"
        :extensions="['p12', 'pfx', 'jks', 'keystore']"
        :disabled="busy"
      />
      <label class="block space-y-2"
        ><span class="block text-secondary">Alias de la clé</span
        ><input v-model="form.alias" class="form-input w-full" required
      /></label>
      <div class="grid gap-5 sm:grid-cols-2">
        <label class="space-y-2"
          ><span class="block text-secondary">Mot de passe du keystore</span
          ><input
            v-model="form.storePassword"
            type="password"
            autocomplete="off"
            class="form-input w-full"
            required
        /></label>
        <label class="space-y-2"
          ><span class="block text-secondary">Mot de passe de la clé (facultatif)</span
          ><input
            v-model="form.keyPassword"
            type="password"
            autocomplete="off"
            class="form-input w-full"
          /><span class="block text-xs text-muted">Vide : utilise celui du keystore.</span></label
        >
      </div>
    </fieldset>
    <p class="text-xs text-muted">
      Clés RSA dans un keystore JKS ou PKCS#12. Pour PKCS#12, la clé et le keystore doivent partager
      le même mot de passe. Les mots de passe JKS sont limités aux caractères ASCII. Alignement des
      bibliothèques natives non compressées sur 16 Kio. APK : 2 Gio maximum.
    </p>
    <button type="submit" class="button" :disabled="busy">
      {{ busy ? 'Alignement, signature et vérification…' : 'Signer l’APK…' }}
    </button>
    <ErrorNotice v-if="error" :error="error" />
    <div v-if="result" role="status" class="rounded-lg border border-positive/30 p-4 text-positive">
      <p>APK signé en v2. Signature et intégrité vérifiées.</p>
      <p class="mt-2 break-all font-mono text-xs">{{ result }}</p>
    </div>
  </form>
</template>
