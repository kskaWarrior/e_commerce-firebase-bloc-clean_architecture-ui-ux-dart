/// Facade for embedding an external dashboard (Looker Studio) in the admin.
///
/// Resolves to the real iframe implementation on Flutter web and a harmless
/// placeholder on every other platform. This keeps `dart:ui_web` /
/// `package:web` out of the mobile build — the whole `lib/` tree compiles for
/// every target, and those APIs only exist on web.
///
/// Consumers import this file and call [buildDashboardEmbed].
library;

export 'dashboard_embed_stub.dart'
    if (dart.library.js_interop) 'dashboard_embed_web.dart';
