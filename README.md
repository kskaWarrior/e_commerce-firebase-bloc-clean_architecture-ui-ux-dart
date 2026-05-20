# e_commerce_app_with_firebase_bloc_clean_architecture

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Integration Testing (CI/CD Ready)

Main feature integration coverage is implemented in:

- `integration_test/main_features_flow_test.dart`

Driver entrypoint:

- `test_driver/integration_test.dart`

### Run locally

1. Start an Android emulator.
2. Verify device is visible:

```bash
flutter devices
```

3. Run integration flow:

```bash
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/main_features_flow_test.dart -d <your-emulator-id>
```

### CI/CD with Codemagic + Firebase Test Lab + Firebase App Distribution

Codemagic workflow file:

- `codemagic.yaml`

Pipeline includes:

1. `flutter analyze`
2. `flutter test --coverage`
3. Build `app-debug.apk` and `app-debug-androidTest.apk`
4. Run instrumentation tests in Firebase Test Lab via `gcloud firebase test android run`

Required secure environment variables in Codemagic:

1. `FIREBASE_PROJECT_ID`: your Firebase/GCP project id
2. `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS`: raw JSON service account key with Firebase Test Lab permissions

Recommended Codemagic variable group name:

- `firebase_credentials`
