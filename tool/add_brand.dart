// Onboards a new customer brand end-to-end.
//
// Usage: dart run tool/add_brand.dart <brand> "<App Name>" [applicationId]
//   <brand>          folder name / flavor / storeId (lowercase, no spaces)
//   <App Name>       display name shown under the launcher icon
//   [applicationId]  optional; defaults to com.wstudios.<brand>. Use the
//                    customer's reverse-domain id when they own one.
//
// What it does:
//   1. Scaffolds brands/<brand>/ from the buybuy template (assets copied as
//      placeholders — replace them with the customer's art).
//   2. Registers Android + iOS apps in the shared Firebase project via the
//      Firebase CLI and captures their appId/apiKey into brand.json.
//   3. Refreshes android/app/google-services.json (multi-client file).
//   4. Prints the remaining manual checklist (keystore, Codemagic group,
//      store doc, owner claims, Looker dashboard).
//
// Prerequisites: firebase CLI logged in (`firebase login`).

import 'dart:convert';
import 'dart:io';

const projectId = 'ecommerceapp-auth-db-cleana';

void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln(
        'Usage: dart run tool/add_brand.dart <brand> "<App Name>" [applicationId]');
    exit(64);
  }
  final brand = args[0];
  final appName = args[1];
  final appId = args.length > 2 ? args[2] : 'com.wstudios.$brand';

  if (!RegExp(r'^[a-z][a-z0-9]*$').hasMatch(brand)) {
    stderr.writeln(
        'Brand must be lowercase alphanumeric starting with a letter '
        '(it becomes an Android flavor name): "$brand" is not.');
    exit(65);
  }
  if (Directory('brands/$brand').existsSync()) {
    stderr.writeln('brands/$brand already exists.');
    exit(65);
  }

  // 1. Scaffold from the buybuy template.
  final template =
      jsonDecode(File('brands/buybuy/brand.json').readAsStringSync())
          as Map<String, dynamic>;
  Directory('brands/$brand/assets').createSync(recursive: true);
  for (final asset in ['logo.png', 'wordmark.png', 'splash.png', 'icon.png']) {
    File('brands/buybuy/assets/$asset').copySync('brands/$brand/assets/$asset');
  }

  // 2. Register Firebase apps and capture their config.
  stdout.writeln('Registering Firebase apps for $appId ...');
  final androidApp = _createApp('android', brand, appId);
  final iosApp = _createApp('ios', brand, appId);
  final androidConfig = _sdkConfig('android', androidApp);

  final config = <String, dynamic>{
    ...template,
    'BRAND_ID': brand,
    'STORE_ID': brand,
    'APP_NAME': appName,
    'HAS_WORDMARK': false,
    'ANDROID_APPLICATION_ID': appId,
    'IOS_BUNDLE_ID': appId,
    'FIREBASE_ANDROID_APP_ID': androidApp,
    'FIREBASE_ANDROID_API_KEY': androidConfig['apiKey'] ??
        template['FIREBASE_ANDROID_API_KEY'],
    'FIREBASE_IOS_APP_ID': iosApp,
    // iOS api key is project-level in practice; reuse until the console says
    // otherwise (apps:sdkconfig ios would need plist parsing).
  };
  File('brands/$brand/brand.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(config)}\n');
  stdout.writeln('Wrote brands/$brand/brand.json');

  // 3. Refresh the multi-client google-services.json. Write to a temp path
  // first: the CLI prompts before overwriting an existing file, which fails
  // in non-interactive runs.
  const tempConfig = 'android/app/google-services.json.tmp';
  final refresh = Process.runSync(
    'firebase',
    [
      'apps:sdkconfig',
      'ANDROID',
      androidApp,
      '--project',
      projectId,
      '-o',
      tempConfig,
    ],
    runInShell: true,
  );
  if (refresh.exitCode != 0 || !File(tempConfig).existsSync()) {
    stderr.write(refresh.stderr);
    stderr.writeln('Failed to refresh google-services.json — run manually:');
    stderr.writeln(
        '  firebase apps:sdkconfig ANDROID $androidApp --project $projectId -o $tempConfig');
    stderr.writeln('  then move it over android/app/google-services.json');
  } else {
    File(tempConfig).copySync('android/app/google-services.json');
    File(tempConfig).deleteSync();
    stdout.writeln('Refreshed android/app/google-services.json');
  }

  stdout.writeln('''

Brand "$brand" scaffolded. Remaining checklist:
  1. Replace placeholder art in brands/$brand/assets/
     (icon.png 1024x1024, splash.png, logo.png, optional wordmark.png
      — set HAS_WORDMARK true if provided).
  2. Adjust the COLOR_* palette in brands/$brand/brand.json.
  3. dart run tool/activate_brand.dart $brand --icons
  4. Generate the upload keystore:
       keytool -genkeypair -v -keystore upload-$brand.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
     and create Codemagic env group brand_$brand (CM_KEYSTORE base64,
     passwords, FIREBASE_ANDROID_APP_ID=$androidApp).
  5. Create the store doc + owner account:
       - Firestore: stores/$brand {name, status:'active', plan, branding}
       - Auth: create the owner's account, then call setStoreOwner
         ({uid, storeId:'$brand'}) as super admin.
  6. Duplicate the Looker Studio template with filter storeId=$brand and
     share view-only with the customer.
  7. Local build check:
       flutter build apk --flavor $brand --dart-define-from-file=brands/$brand/brand.json
''');
}

String _createApp(String platform, String brand, String appId) {
  final idFlag = platform == 'android' ? '--package-name' : '--bundle-id';
  final result = Process.runSync(
    'firebase',
    [
      'apps:create',
      platform,
      '$brand ($platform)',
      idFlag,
      appId,
      '--project',
      projectId,
    ],
    runInShell: true,
  );
  final output = '${result.stdout}\n${result.stderr}';
  final match = RegExp(r'App ID: (\S+)').firstMatch(output);
  if (result.exitCode != 0 || match == null) {
    stderr.write(output);
    stderr.writeln('Failed to create $platform app.');
    exit(70);
  }
  final firebaseAppId = match.group(1)!;
  stdout.writeln('  $platform app: $firebaseAppId');
  return firebaseAppId;
}

Map<String, dynamic> _sdkConfig(String platform, String firebaseAppId) {
  final result = Process.runSync(
    'firebase',
    [
      'apps:sdkconfig',
      platform.toUpperCase(),
      firebaseAppId,
      '--project',
      projectId,
    ],
    runInShell: true,
  );
  if (result.exitCode != 0) {
    return const {};
  }
  final output = result.stdout.toString();
  final apiKey =
      RegExp(r'"current_key":\s*"([^"]+)"').firstMatch(output)?.group(1);
  return {'apiKey': apiKey};
}
