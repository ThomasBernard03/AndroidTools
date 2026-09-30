# Android Tools

Application desktop **Rust + Tauri 2 + Vue 3 / TypeScript + Tailwind CSS 4** pour inspecter les appareils Android connectés en USB et analyser les fichiers APK localement.

## Fonctionnalités

- Détection des interfaces USB ADB à l’ouverture, puis actualisation manuelle avec le bouton dédié.
- Sélection explicite d’un appareil, y compris lorsque plusieurs téléphones ont le même modèle.
- Lecture du fabricant, de la marque, du modèle, du numéro de série, de la version Android, du niveau API, du correctif de sécurité, du build, du bootloader, du matériel, du SoC et des architectures CPU.
- Affichage des identifiants USB et de l’empreinte du build.
- États de chargement, liste vide, erreurs USB, nouvelle tentative et déconnexion.
- Identité ADB persistante propre à l’application.
- Analyse APK par glisser-déposer ou sélection de fichier : manifeste XML décodé, permissions, certificats et empreintes SHA-1/SHA-256.

La communication utilise **`adb_client` en USB direct**, sans exécutable `adb`, serveur ADB ou Android SDK à installer. `rusb` sert à identifier précisément chaque connexion USB ; le protocole ADB est pris en charge par `adb_client`. La bibliothèque native `libusb` est compilée avec la feature `vendored`, sans exécutable annexe à distribuer.

La partie appareils cible les téléphones physiques en USB. L’explorateur de fichiers, logcat, l’installation d’APK, les émulateurs et la connexion réseau ne sont pas encore implémentés.

## Analyse APK

Ouvrez **Analyse APK** dans la barre latérale, puis déposez un fichier `.apk` depuis le Finder/l’explorateur ou utilisez **Choisir un APK**. Un dépôt dans la fenêtre ouvre automatiquement cette vue. Aucun téléphone, SDK Android, `aapt` ou `apksigner` n’est nécessaire.

- **Résumé** : nom de l’application, package, version, taille et SDK minimum/cible lorsqu’ils sont renseignés.
- **Signature** : schémas v1, v2, v3 et v3.1 reconnus, sujets et émetteurs des certificats, dates, numéro de série, algorithme et empreintes SHA-1/SHA-256.
- **Manifeste** : contenu d’`AndroidManifest.xml`, décodé depuis le format binaire Android et affiché en lecture seule.
- **Permissions** : recherche dans les permissions demandées, celles spécifiques à l’API 23+, et celles définies par l’application ; affichage du SDK maximum et du niveau de protection lorsqu’ils sont déclarés.

L’analyse utilise la bibliothèque Rust `apk-info`. Les certificats sont **extraits, pas vérifiés cryptographiquement** : leur présence ne garantit ni l’intégrité de l’APK ni son acceptation par Android. Un fichier sans certificat reconnu est présenté comme tel, et non comme formellement non signé. Le schéma v4 (fichier `.idsig` externe) n’est pas analysé. Si plusieurs blocs v1 existent, la bibliothèque ne décode que le premier ; cette limite est signalée dans les résultats.

Une erreur de lecture des signatures laisse accessibles le manifeste et les permissions. Un seul APK est analysé à la fois ; les dépôts successifs privilégient le dernier fichier demandé. Les fichiers restent sur l’ordinateur, ne sont ni exécutés ni installés. Les métadonnées décompressées de plus de 64 Mio sont refusées. Les conteneurs `.aab`, `.apkm` et `.xapk` ne sont pas pris en charge par cette vue.

## Démarrage sur macOS

### Prérequis

- Node.js : une version LTS récente, idéalement **24.15 ou ultérieure dans la branche 24**.
- Rust stable, version 1.90 minimum, avec Cargo, rustfmt et Clippy.
- Xcode ou les Command Line Tools d’Apple.

Pour installer Rust via Homebrew :

```bash
brew install rustup pkgconf
export PATH="$(brew --prefix rustup)/bin:$PATH"
rustup default stable
rustup component add rustfmt clippy
```

Ajoutez le chemin de `rustup` à votre configuration de shell pour les prochains terminaux. La formule Homebrew actuelle ne fournit plus `rustup-init`. Une installation système de `libusb` n’est pas requise avec la configuration `vendored` du projet.

### Lancement

Depuis la racine du dépôt :

```bash
npm ci
npm run tauri dev
```

`npm run dev` lance uniquement l’interface dans un navigateur : l’accès USB, le glisser-déposer natif et l’analyse APK nécessitent l’application desktop. Aucune donnée de démonstration n’est utilisée.

### Connecter un téléphone

1. Activez les options pour les développeurs puis le **débogage USB**.
2. Branchez le téléphone avec un câble USB permettant le transfert de données.
3. Sélectionnez-le dans la liste de l’application.
4. Déverrouillez-le et acceptez la demande d’autorisation ADB. Cochez l’autorisation permanente si vous souhaitez conserver la confiance.
5. Si la demande expire avant votre validation, cliquez sur **Réessayer**.

Les champs non fournis par Android sont affichés comme « Non disponible ». Le branchement USB est détecté avant l’authentification : un appareil présent dans la liste n’est pas nécessairement autorisé pour ADB.

La sélection est liée à la connexion USB actuelle, pas à une préférence enregistrée. Lors d’une déconnexion détectée, elle est effacée ; il faut sélectionner de nouveau l’appareil après reconnexion. Les informations sont relues lors de la sélection ou avec le bouton dédié.

## Dépannage USB

### Interface occupée

Un serveur ADB lancé par Android Studio peut déjà posséder l’interface USB. Si vous disposez des Platform Tools, vous pouvez l’arrêter avec :

```bash
adb kill-server
```

Fermez également l’outil qui le redémarre automatiquement. L’application n’arrête aucun processus externe elle-même.

### Appareil absent

Vérifiez le câble, le débogage USB et, selon le fabricant, le mode de connexion « Transfert de fichiers ». Les interfaces MTP seules ne permettent pas l’accès ADB.

### Autorisation

La clé RSA privée est enregistrée dans le dossier de données de l’application. Sur macOS :

```text
~/Library/Application Support/com.thomasbernard.androidtools/adbkey.pem
```

Elle est distincte de celle des Platform Tools et réutilisée entre les connexions et les lancements. Sur Unix, elle est créée avec les permissions `0600`. Une clé existante invalide produit une erreur explicite plutôt qu’un remplacement silencieux.

### Autres plateformes

L’architecture est multiplateforme, mais le fonctionnement matériel doit être vérifié sur chaque OS :

- **Windows** : outils de compilation MSVC, WebView2 et pilote USB compatible WinUSB pour l’interface ADB.
- **Linux** : dépendances système Tauri/WebKitGTK, outils de compilation et permissions USB/règles udev adaptées.

Consultez les [prérequis Tauri](https://v2.tauri.app/start/prerequisites/) pour les paquets propres à chaque plateforme. Le débogage USB reste nécessaire dans tous les cas.

## Architecture

```text
src/
  App.vue                         Composition de l’écran
  components/                     Icônes et affichage partagé des erreurs
  features/apk/
    api.ts                        Commande d’analyse, dialogue et événements de dépôt
    useApk.ts                     Analyse asynchrone et gestion des dépôts successifs
    components/                   Résumé, certificats, manifeste et permissions
  features/devices/
    api.ts                        Appels IPC Tauri et normalisation des erreurs
    types.ts                      Contrats TypeScript
    useDevices.ts                 Sélection, actualisation manuelle et état asynchrone
    components/                   Composants Vue de présentation

src-tauri/
  src/commands.rs                 Commandes IPC, exécutées en spawn_blocking
  src/apk/                        Analyse APK, permissions et certificats (sans Tauri)
  src/devices/
    usb.rs                        Énumération et lecture via adb_client
    identity.rs                   Persistance de l’identité ADB
    properties.rs                 Décodage de getprop
    models.rs                     Réponses sérialisables
    error.rs                      Erreurs structurées
  capabilities/main.json          Permissions de la fenêtre locale
```

Les opérations USB et l’analyse des APK n’occupent pas le thread d’interface. Les lectures sont sérialisées ; les changements rapides de sélection sont regroupés et les réponses obsolètes sont ignorées. La liste des appareils est chargée à l’ouverture, puis uniquement sur demande : actualisez-la après un branchement ou un débranchement. Seules des commandes métier sont exposées : le frontend ne peut pas envoyer de commande shell arbitraire. La navigation entre les deux vues utilise un état Vue local, sans routeur ni store global.

## Vérifications

```bash
npm run build
npm run lint
npm test
npm run format:check
cargo fmt --manifest-path src-tauri/Cargo.toml --check
cargo test --manifest-path src-tauri/Cargo.toml
cargo clippy --manifest-path src-tauri/Cargo.toml --all-targets -- -D warnings
```

Les tests automatisés couvrent le parsing des propriétés, la persistance des clés, la sélection, les réponses obsolètes, les erreurs, les déconnexions et l’actualisation manuelle. Ils ne remplacent pas un essai USB sur un téléphone physique.

Les tests APK génèrent des archives temporaires avec un véritable manifeste AXML binaire et un certificat X.509 dans un bloc v2. Ils vérifient également les archives invalides, les permissions, les erreurs partielles, le cycle de vie des événements de dépôt et les analyses successives. Les données de test ne constituent pas une application Android installable et les signatures ne sont pas vérifiées.

Pour un essai matériel : branchez deux appareils (idéalement du même modèle), vérifiez que chacun affiche ses propres informations, changez de sélection pendant une lecture, refusez puis acceptez une autorisation et débranchez l’appareil sélectionné. Vérifiez également le cas où un serveur ADB occupe déjà l’interface.

## Build desktop

```bash
npm run tauri build
```

Les bundles sont générés dans `src-tauri/target/release/bundle/`. La signature Developer ID et la notarisation sont à configurer avant une distribution publique sur macOS.

Le workflow `.github/workflows/release.yml` provient encore de l’ancienne application Flutter : sa migration vers une publication Tauri reste à faire avant d’utiliser cette automatisation.
