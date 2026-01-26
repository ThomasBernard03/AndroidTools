<a href='https://nextchat.club'>
  <img src="https://github.com/user-attachments/assets/83bdcc07-ae5e-4954-a53a-ac151ba6ccf3" width="1000" alt="icon"/>
</a>

<h1 align="center">Android Tools</h1>

# android_tools

```shell
fvm flutter clean && fvm flutter pub get && fvm dart run build_runner build -d
```

## Roadmap
- Update devices list when usb device is plug/unplug
- Real time SQL database
- Stack same logcat lines (like VSCode)
- In app updates
- Preview text & XML files in file explorer

## Install application

### Macos
1. Download latest version from github release.
2. Unzip installer
3. Double clic on application
4. A popup will show "Android tools not opened"
5. Go to settings -> Confidentialité et sécurité, scroll to bottom
6. android_tools 2 a été bloqué, clic on `open`


## Running the Project with a Sentry DSN

This project supports Sentry error tracking via a **compile-time configuration** using `--dart-define`.

For security reasons, the Sentry DSN is **not included** in the repository. You must provide it yourself when running or building the app.

---

### How It Works

The project reads the DSN using:

```dart
const sentryDsn = String.fromEnvironment(
  'SENTRY_DSN',
  defaultValue: '',
);
```

So when you wan't to launch projet, don't forget `--dart-define=SENTRY_DSN`

Ex :
```shell
fvm flutter run --dart-define=SENTRY_DSN=your_dsn
```



```shell
fvm flutter clean && fvm flutter pub get && fvm dart run build_runner build -d
```

```shell
    Successfully installed the Sentry Flutter SDK!

    Next steps:
    1. Run flutter run to test the setup - we've added a test error that will trigger on app start
    2. For production builds, run flutter build apk --obfuscate --split-debug-info=build/debug-info (or ios/macos) then flutter pub run sentry_dart_plugin to upload debug symbols
    3. View your test error and transaction data at https://thomas-bernard.sentry.io/issues/?project=4510551404183632

    Learn more:
    - Debug Symbols: https://docs.sentry.io/platforms/dart/guides/flutter/debug-symbols/
    - Performance Monitoring: https://docs.sentry.io/platforms/dart/guides/flutter/performance/
    - Integrations: https://docs.sentry.io/platforms/dart/guides/flutter/integrations/
```

## Build

### Macos

Build app
```shell
fvm flutter build macos --dart-define=SENTRY_DSN=your_sentry_dsn  --obfuscate --split-debug-info=build/debug-info
```

Dans Xcode :
	1.	Sélectionne le scheme Release
	2.	Menu Product → Build
	3.	Puis Product → Archive

Une fois l’archive créée :
	•	Clique sur Distribute App
	•	Choisis Copy App
	•	Exporte ton .app quelque part


Check signature :
```shell
codesign -dv android_tools.app
```

// THIS LINE WORKS !!
```shell
zip -r android_tools.zip android_tools.app
```

TODO test this :
xattr -dr com.apple.quarantine MonApp.app

We use this awesome package to manage application update : [flutter_desktop_updater](https://github.com/MarlonJD/flutter_desktop_updater)

So you can build the application with this command :
```shell
fvm dart run desktop_updater:release macos 
fvm dart run desktop_updater:archive macos 
```
(Don't forget to pass `--dart-define` arguments to the first command)