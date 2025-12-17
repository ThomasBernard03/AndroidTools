# android_tools

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

TODO ReACTIVER LE SANDBOX


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
