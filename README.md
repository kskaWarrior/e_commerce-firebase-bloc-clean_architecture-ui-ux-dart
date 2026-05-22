# e_commerce_app_with_firebase_bloc_clean_architecture

Mobile e-commerce demo built with Flutter and Clean Architecture to showcase scalable engineering, reactive cloud-native design, and production-ready quality. It covers the full flow from authenticated user actions to real-time BI updates through an event-driven serverless pipeline: Firestore → Firebase Functions → BigQuery → Looker Studio, with CI/CD, automated testing, and observability via Crashlytics and Firebase Performance.

The goal was to simulate a complete real-world product flow: from user authentication in the app to sales data being automatically processed in a real-time Business Intelligence pipeline.

## Main technologies and concepts applied

- Flutter + Dart
- Clean Architecture + SOLID
- Flutter Bloc for state management
- Repository Pattern + Dependency Injection
- Firebase Authentication, Firestore, Functions, and Storage
- Serverless Cloud-Native Architecture
- Event-Driven Design
- BigQuery + Looker Studio (BI)
- Automated real-time ETL (Extract, Transform, and Load)
- CI/CD with Codemagic
- Firebase Test Lab + App Distribution
- Unit, widget, and integration tests
- Performance and crash monitoring with Crashlytics and Firebase Performance

## Key architecture points

- Clear separation between layers (Presentation, Domain, Data, and Services)
- Modularity and scalability
- Event-based asynchronous processing
- Local persistence and cross-session cache
- Reactive synchronization for favorites and cart
- Performance and observability strategies
- Test coverage greater than 70% (unit, widget, and integration)
- Automated pipeline for build, testing, and distribution

In addition to the iOS and Android application, the project also demonstrates integration between mobile development, serverless backend, and analytics:

Firestore → Firebase Functions → BigQuery → Looker Studio

In other words, each completed sale automatically triggers an ETL data flow and a real-time BI dashboard update.

#Flutter #Dart #MobileDevelopment #CleanArchitecture #Firebase #BigQuery #BusinessIntelligence #CI_CD #SoftwareEngineering #AppDevelopment #FlutterDev #EventDrivenArchitecture #CloudNative #SeniorDeveloper

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
