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
- Rubrique **APK** : analyse, génération de keystore PKCS#12 et signature APK v2 intégrées en Rust, sans JDK ni SDK Android à installer.
- Historique persistant des 10 derniers chemins APK analysés, avec réouverture et retrait individuel.
- Explorateur de fichiers : stockage partagé, racine Android, données privées des applications debuggables, aperçu texte, transferts et gestion des dossiers.

La communication utilise **`adb_client` en USB direct**, sans exécutable `adb`, serveur ADB ou Android SDK à installer. `rusb` sert à identifier précisément chaque connexion USB ; le protocole ADB est pris en charge par `adb_client`. La bibliothèque native `libusb` est compilée avec la feature `vendored`, sans exécutable annexe à distribuer.

La partie appareils cible les téléphones physiques en USB. Logcat, l’installation d’APK, les émulateurs et la connexion réseau ne sont pas encore implémentés.

## Explorateur de fichiers

Sélectionnez un téléphone, puis ouvrez **Explorateur de fichiers**. Les raccourcis donnent accès au stockage partagé (`/sdcard`), à la racine Android et aux données des applications (`/data/data`). Un clic sur un dossier l’ouvre ; le fil d’Ariane et le bouton parent permettent de remonter. La recherche conserve tous les éléments affichés et fait défiler la liste vers la première correspondance, y compris parmi les fichiers cachés. **Précédent / Suivant** permettent de parcourir les résultats en boucle ; **Entrée / Maj+Entrée** font de même depuis le champ de recherche. **Actualiser** relit son contenu.

Comme dans l’ancienne version Flutter, `/data` et `/data/data` sont des emplacements virtuels : la liste des packages vient du gestionnaire Android, puis les lectures dans `/data/data/<package>` passent par **`run-as`**. Tous les packages de l’utilisateur principal (0) sont listés, mais leurs données ne sont accessibles que si l’application est debuggable et autorise `run-as`. Les refus d’accès sont affichés avec les détails Android. Les profils secondaires/professionnels ne sont pas pris en charge.

Les fichiers ordinaires disposent d’un aperçu texte UTF-8 limité aux **256 premiers Kio** ; les fichiers binaires sont signalés. Les liens symboliques et fichiers spéciaux sont affichés mais ne sont pas ouverts ni transférés. Les répertoires système restent soumis aux permissions Android. La lecture des métadonnées utilise les commandes Android `stat` et `head` via ADB USB, sans exécutable externe sur l’ordinateur.

- **Télécharger** enregistre un fichier sur l’ordinateur ou copie récursivement un dossier dans le répertoire choisi. Pour un dossier, la destination ne doit pas déjà exister.
- **Envoyer un fichier / Envoyer un dossier** copie l’élément sélectionné dans le dossier Android courant, avec son nom d’origine. Les éléments existants ne sont pas écrasés. Les dossiers vides sont conservés.
- **Nouveau dossier** crée un dossier dans l’emplacement courant.
- **Supprimer** demande confirmation puis supprime l’élément et, pour un dossier, tout son contenu.

Ces actions sont disponibles dans les dossiers accessibles, y compris les données privées via `run-as`, mais pas dans les listes virtuelles `/data` et `/data/data`. Un transfert interrompu peut laisser un dossier partiellement copié ; choisissez une nouvelle destination pour réessayer. L’envoi utilise un fichier temporaire dans `/data/local/tmp`, supprimé à la fin de l’opération lorsque l’appareil reste accessible.

## Analyse APK

Ouvrez **APK → Analyse APK** dans la barre latérale, puis déposez un fichier `.apk` depuis le Finder/l’explorateur ou utilisez **Choisir un APK**. Un dépôt dans la fenêtre ouvre automatiquement cette vue. Aucun téléphone, SDK Android, `aapt` ou `apksigner` n’est nécessaire.

La section **APK récents** conserve les chemins des 10 derniers fichiers analysés avec succès, du plus récent au plus ancien, même après redémarrage. Réanalyser un chemin le remonte en tête sans doublon. Cliquez sur une entrée pour relire le fichier ; s’il a été déplacé ou supprimé, une erreur de lecture est affichée. **Retirer** supprime uniquement l’entrée de l’historique. Les chemins sont stockés dans `apk-history.sqlite`, une base SQLite du dossier de données de l’application (`~/Library/Application Support/com.thomasbernard.androidtools/` sur macOS). Une erreur de sauvegarde de l’historique est signalée sans masquer le résultat de l’analyse.

- **Résumé** : nom de l’application, package, version, taille et SDK minimum/cible lorsqu’ils sont renseignés.
- **Signature** : schémas v1, v2, v3 et v3.1 reconnus, sujets et émetteurs des certificats, dates, numéro de série, algorithme et empreintes SHA-1/SHA-256.
- **Manifeste** : contenu d’`AndroidManifest.xml`, décodé depuis le format binaire Android et affiché en lecture seule.
- **Permissions** : recherche dans les permissions demandées, celles spécifiques à l’API 23+, et celles définies par l’application ; affichage du SDK maximum et du niveau de protection lorsqu’ils sont déclarés.

L’analyse utilise la bibliothèque Rust `apk-info`. Les certificats sont **extraits, pas vérifiés cryptographiquement** : leur présence ne garantit ni l’intégrité de l’APK ni son acceptation par Android. Un fichier sans certificat reconnu est présenté comme tel, et non comme formellement non signé. Le schéma v4 (fichier `.idsig` externe) n’est pas analysé. Si plusieurs blocs v1 existent, la bibliothèque ne décode que le premier ; cette limite est signalée dans les résultats.

Une erreur de lecture des signatures laisse accessibles le manifeste et les permissions. Un seul APK est analysé à la fois ; les dépôts successifs privilégient le dernier fichier demandé. Les fichiers restent sur l’ordinateur, ne sont ni exécutés ni installés. Les métadonnées décompressées de plus de 64 Mio sont refusées. Les conteneurs `.aab`, `.apkm` et `.xapk` ne sont pas pris en charge par cette vue.

## Génération de keystore

Dans **APK → Génération de keystore**, renseignez l’alias, le nom du certificat, sa validité et un mot de passe d’au moins six caractères. L’organisation et le code pays sont facultatifs. Choisissez ensuite un nouveau fichier `.p12` dans le dialogue d’enregistrement.

La validité affiche le nombre de jours, son équivalent approximatif en années et la date d’expiration. Le bouton **Générer un mot de passe** remplit automatiquement les deux champs avec un mot de passe aléatoire de 24 caractères. Un fichier compagnon `<nom>.p12.json` est enregistré dans le même dossier : alias, mots de passe du keystore et de la clé, identité du certificat, durée et dates de création et d’expiration (UTC). Les mots de passe y figurent en clair ; conservez les deux fichiers en lieu sûr. Aucun fichier existant n’est remplacé.

La génération utilise `rsa`, `rcgen` et `p12-keystore` : clé **RSA 3072 bits**, certificat X.509 auto-signé et keystore **PKCS#12 chiffré en AES-256** avec MAC SHA-256. La clé et le keystore partagent le même mot de passe. Le chemin et l’alias générés préremplissent le formulaire de signature pendant la session. Conservez le fichier, son alias et son mot de passe pour signer les mises à jour de votre application.

## Signature d’APK

Dans **APK → Signature d’APK**, choisissez un APK, un keystore, l’alias et les mots de passe, puis un nouveau fichier de sortie. Le traitement se fait en Rust avec `zip`, `apksig`, `p12-keystore` et `jks` :

1. Lecture de la clé RSA et contrôle de sa correspondance avec le certificat.
2. Retrait des anciennes signatures et du certificat de source stamp, puis alignement des entrées non compressées sur 4 octets et des bibliothèques `.so` sur **16 Kio**.
3. Signature **APK v2 RSA/SHA-256**.
4. Vérification de la signature et comparaison de l’empreinte du contenu avant publication du résultat.

Cette signature cible **Android 7.0 et ultérieur (API 24+)**. Les schémas v1, v3 et v4 ne sont pas générés ; le manifeste et son SDK minimum restent inchangés. Un APK déclarant un SDK minimum inférieur à 24 ne pourra donc plus être installé sur ces anciennes versions après cette signature. Les clés EC/DSA et la rotation de clés ne sont pas prises en charge.

Les keystores JKS et PKCS#12 sont acceptés (16 Mio maximum). Pour PKCS#12, la clé et le keystore doivent partager le même mot de passe. JKS accepte des mots de passe distincts, limités aux caractères ASCII par la bibliothèque utilisée. Les APK sont limités à 2 Gio et aux méthodes ZIP stockée/Deflate.

Les opérations s’exécutent hors du thread d’interface. Le fichier source est conservé et aucun fichier existant n’est écrasé. Les fichiers temporaires sont nettoyés automatiquement ; les sorties ont des permissions `0600` sur Unix. Le mot de passe généré ou saisi lors de la création du keystore est enregistré dans son fichier compagnon ; les champs de mot de passe sont vidés après chaque opération. Aucun outil externe n’est exécuté pour générer ou signer.

## Réglages et rapports de crash

La rubrique **Réglages**, en bas de la barre latérale, permet de :

- ouvrir `android-tools.log` avec l’application associée aux fichiers de log ; le journal est créé dans le dossier de logs Tauri, avec rotation à 5 Mo et une archive conservée ;
- ouvrir le formulaire de création d’issue GitHub ou le dépôt open source dans le navigateur ;
- rechercher les mises à jour : Sparkle dans un bundle macOS compilé avec `macos-updater`, sinon comparaison de la version courante avec la dernière release stable GitHub et lien vers ses téléchargements ;
- activer ou désactiver les rapports de crash Sentry pour Vue et Rust. Le choix est enregistré dans `settings.json` dans le dossier de données Tauri et s’applique aux nouveaux événements sans redémarrage. Les rapports déjà envoyés ne sont pas supprimés.

Comme dans l’ancienne application Flutter, configurez `SENTRY_DSN` au moment de compiler :

```bash
SENTRY_DSN="https://<public-key>@<host>.ingest.sentry.io/<project-id>" npm run tauri build
```

La même valeur est utilisée par le backend Rust et le frontend Vue. Sans DSN, aucun rapport n’est envoyé. Le reporting est activé par défaut lorsqu’un DSN est fourni. Les erreurs Vue, les exceptions JavaScript non interceptées et les paniques Rust sont collectées ; les erreurs métier affichées dans l’interface ne sont pas automatiquement envoyées. Les captures d’écran, replays, props Vue, traces de performance et breadcrumbs ne sont pas collectés. Pour un Sentry auto-hébergé, ajoutez son origine à `app.security.csp.connect-src` dans `src-tauri/tauri.conf.json`.

Les mots de passe du formulaire de signature disposent chacun d’un bouton **Afficher / Masquer**.

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
  features/files/
    api.ts                        Commandes typées de liste et d’aperçu
    useFiles.ts                   Navigation et lectures USB regroupées
    components/                   Explorateur et aperçu texte

src-tauri/
  src/commands.rs                 Commandes IPC, exécutées en spawn_blocking
  src/apk/                        Analyse APK, permissions et certificats (sans Tauri)
  src/apk_tools.rs                 Keystores, alignement, signature et vérification APK v2
  src/devices/
    usb.rs                        Énumération et lecture via adb_client
    files.rs                      Navigation, run-as et parsing des fichiers
    identity.rs                   Persistance de l’identité ADB
    properties.rs                 Décodage de getprop
    models.rs                     Réponses sérialisables
    error.rs                      Erreurs structurées
  capabilities/main.json          Permissions de la fenêtre locale
```

Les opérations USB et l’analyse des APK n’occupent pas le thread d’interface. Les lectures sont sérialisées ; les changements rapides de sélection sont regroupés et les réponses obsolètes sont ignorées. La liste des appareils est chargée à l’ouverture, puis uniquement sur demande : actualisez-la après un branchement ou un débranchement. Seules des commandes métier sont exposées : le frontend ne peut pas envoyer de commande shell arbitraire. La navigation entre les vues utilise un état Vue local, sans routeur ni store global.

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

Les tests de **signature** génèrent un keystore et signent réellement une archive de test. Ils couvrent PKCS#12, JKS avec mots de passe distincts, la re-signature, les erreurs de mot de passe, l’alignement, la conservation du fichier source, le refus d’écrasement et la détection d’un contenu altéré. Un test facultatif contrôle également l’interopérabilité avec les outils officiels (uniquement requis pour ce test) :

```bash
ANDROID_TOOLS_APKSIGNER="$ANDROID_HOME/build-tools/36.1.0/apksigner" \
ANDROID_TOOLS_ZIPALIGN="$ANDROID_HOME/build-tools/36.1.0/zipalign" \
cargo test --manifest-path src-tauri/Cargo.toml native_signatures_are_compatible_with_android_tools -- --ignored --nocapture
```

Adaptez la version des Build Tools et rendez `keytool` accessible dans le `PATH`. Ce test vérifie la signature à partir de l’API 24 et ne remplace pas un essai d’installation sur un appareil.

Pour un essai matériel : branchez deux appareils (idéalement du même modèle), vérifiez que chacun affiche ses propres informations, changez de sélection pendant une lecture, refusez puis acceptez une autorisation et débranchez l’appareil sélectionné. Vérifiez également le cas où un serveur ADB occupe déjà l’interface.

## Build desktop

```bash
npm run tauri build
```

Les bundles sont générés dans `src-tauri/target/release/bundle/`. La signature Developer ID et la notarisation sont à configurer avant une distribution publique sur macOS.

Le workflow `.github/workflows/release.yml` provient encore de l’ancienne application Flutter : sa migration vers une publication Tauri reste à faire avant d’utiliser cette automatisation.
