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
