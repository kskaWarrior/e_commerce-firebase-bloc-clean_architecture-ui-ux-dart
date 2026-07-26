// Activates a brand for local development and CI builds.
//
// Usage: dart run tool/activate_brand.dart <brand> [--platforms web]
//
// What it does (v1):
//   1. Validates brands/<brand>/brand.json and its required assets.
//   2. Copies brand assets to assets/brand/ under fixed filenames so Dart
//      code can reference them without per-brand pubspec changes.
//   3. Rewrites web/manifest.json (name, colors, description) and
//      web/index.html (<title>, apple title, description).
//   4. Writes brand.current.json at the repo root as a stable pointer for
//      launch configs and CI.
//
// Later phases extend this with icon/splash generation and iOS xcconfig.

import 'dart:convert';
import 'dart:io';

const requiredKeys = [
  'BRAND_ID',
  'STORE_ID',
  'APP_NAME',
  'ANDROID_APPLICATION_ID',
  'IOS_BUNDLE_ID',
  'COLOR_PRIMARY',
  'COLOR_BACKGROUND',
];

const assetFiles = ['logo.png', 'wordmark.png', 'splash.png', 'icon.png'];

void main(List<String> args) {
  if (args.isEmpty || args.first.startsWith('--')) {
    stderr.writeln('Usage: dart run tool/activate_brand.dart <brand>');
    exit(64);
  }
  final brand = args.first;
  final brandDir = Directory('brands/$brand');
  final configFile = File('brands/$brand/brand.json');

  if (!brandDir.existsSync() || !configFile.existsSync()) {
    stderr.writeln('Brand "$brand" not found (expected ${configFile.path}).');
    stderr.writeln('Available brands: ${listBrands().join(', ')}');
    exit(66);
  }

  final config = jsonDecode(configFile.readAsStringSync());
  if (config is! Map<String, dynamic>) {
    stderr.writeln('brand.json must be a flat JSON object.');
    exit(65);
  }
  final missing = requiredKeys
      .where((k) => config[k] == null || config[k].toString().isEmpty)
      .toList();
  if (missing.isNotEmpty) {
    stderr.writeln('brand.json is missing required keys: $missing');
    exit(65);
  }
  if (config['BRAND_ID'] != brand) {
    stderr.writeln(
        'BRAND_ID "${config['BRAND_ID']}" does not match folder "$brand".');
    exit(65);
  }

  copyBrandAssets(brand, config);
  rewriteWebManifest(config);
  rewriteWebIndex(config);
  writeIosBrandXcconfig(config);
  writeIconSplashConfigs(brand, config);
  if (args.contains('--icons')) {
    runIconSplashGenerators(brand);
  }

  File('brand.current.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(config)}\n',
  );

  stdout.writeln('Activated brand "$brand" '
      '(store: ${config['STORE_ID']}, app: ${config['APP_NAME']}).');
  stdout.writeln('Run/build with: '
      '--dart-define-from-file=brands/$brand/brand.json');
}

List<String> listBrands() {
  final dir = Directory('brands');
  if (!dir.existsSync()) return const [];
  return dir
      .listSync()
      .whereType<Directory>()
      .map((d) => d.uri.pathSegments.where((s) => s.isNotEmpty).last)
      .toList()
    ..sort();
}

void copyBrandAssets(String brand, Map<String, dynamic> config) {
  final outDir = Directory('assets/brand');
  outDir.createSync(recursive: true);
  final hasWordmark = config['HAS_WORDMARK'] == true;

  for (final name in assetFiles) {
    final source = File('brands/$brand/assets/$name');
    if (!source.existsSync()) {
      if (name == 'wordmark.png' && !hasWordmark) continue;
      stderr.writeln('Missing required asset brands/$brand/assets/$name');
      exit(66);
    }
    source.copySync('assets/brand/$name');
  }
  stdout.writeln('Copied brand assets to assets/brand/.');
}

String hexToCss(String argb) {
  // brand.json colors are AARRGGBB; web manifest wants #RRGGBB.
  final rgb = argb.length == 8 ? argb.substring(2) : argb;
  return '#${rgb.toUpperCase()}';
}

void rewriteWebManifest(Map<String, dynamic> config) {
  final file = File('web/manifest.json');
  if (!file.existsSync()) return;
  final manifest = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final appName = config['APP_NAME'].toString();
  manifest['name'] = appName;
  manifest['short_name'] = appName;
  manifest['description'] = '$appName online store';
  manifest['theme_color'] = hexToCss(config['COLOR_PRIMARY'].toString());
  manifest['background_color'] =
      hexToCss(config['COLOR_BACKGROUND'].toString());
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('    ').convert(manifest)}\n',
  );
  stdout.writeln('Updated web/manifest.json.');
}

void writeIosBrandXcconfig(Map<String, dynamic> config) {
  // Consumed via `#include? "Brand.xcconfig"` in ios/Flutter/{Debug,Release}
  // .xcconfig. Gitignored: the active brand decides the bundle id at build
  // time (iOS builds run on CI only — owner develops on Windows).
  final file = File('ios/Flutter/Brand.xcconfig');
  file.writeAsStringSync('''
PRODUCT_BUNDLE_IDENTIFIER = ${config['IOS_BUNDLE_ID']}
BRAND_DISPLAY_NAME = ${config['APP_NAME']}
''');
  stdout.writeln('Wrote ios/Flutter/Brand.xcconfig.');
}

void writeIconSplashConfigs(String brand, Map<String, dynamic> config) {
  final background = hexToCss(config['COLOR_BACKGROUND'].toString());

  // Android launcher icons land in the flavor-specific res folder, so each
  // brand's icons coexist. iOS icons write into the single Runner asset
  // catalog — run that variant on CI right before an iOS build only.
  File('flutter_launcher_icons-$brand.yaml').writeAsStringSync('''
flutter_launcher_icons:
  android: true
  ios: false
  image_path: brands/$brand/assets/icon.png
  adaptive_icon_background: "$background"
  adaptive_icon_foreground: brands/$brand/assets/icon.png
''');

  File('flutter_native_splash-$brand.yaml').writeAsStringSync('''
flutter_native_splash:
  color: "$background"
  image: brands/$brand/assets/splash.png
  android: true
  ios: false
  web: false
''');
  stdout.writeln('Wrote icon/splash generator configs for "$brand".');
}

void runIconSplashGenerators(String brand) {
  stdout.writeln('Generating launcher icons and native splash...');
  final icons = Process.runSync(
    'dart',
    ['run', 'flutter_launcher_icons', '-f', 'flutter_launcher_icons-$brand.yaml'],
    runInShell: true,
  );
  stdout.write(icons.stdout);
  if (icons.exitCode != 0) {
    stderr.write(icons.stderr);
    stderr.writeln('flutter_launcher_icons failed.');
    exit(icons.exitCode);
  }

  final splash = Process.runSync(
    'dart',
    [
      'run',
      'flutter_native_splash:create',
      '--path=flutter_native_splash-$brand.yaml',
      '--flavor',
      brand,
    ],
    runInShell: true,
  );
  stdout.write(splash.stdout);
  if (splash.exitCode != 0) {
    stderr.write(splash.stderr);
    stderr.writeln('flutter_native_splash failed.');
    exit(splash.exitCode);
  }
}

void rewriteWebIndex(Map<String, dynamic> config) {
  final file = File('web/index.html');
  if (!file.existsSync()) return;
  final appName = config['APP_NAME'].toString();
  var html = file.readAsStringSync();
  html = html.replaceFirst(
      RegExp(r'<title>[^<]*</title>'), '<title>$appName</title>');
  html = html.replaceFirst(
      RegExp(r'<meta name="apple-mobile-web-app-title" content="[^"]*">'),
      '<meta name="apple-mobile-web-app-title" content="$appName">');
  html = html.replaceFirst(
      RegExp(r'<meta name="description" content="[^"]*">'),
      '<meta name="description" content="$appName online store">');
  file.writeAsStringSync(html);
  stdout.writeln('Updated web/index.html.');
}
