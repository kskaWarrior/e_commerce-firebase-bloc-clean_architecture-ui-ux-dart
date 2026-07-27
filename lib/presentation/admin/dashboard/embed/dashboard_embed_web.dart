import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// View types already registered this session. An identical URL reuses its
/// factory instead of registering a fresh one on every rebuild.
final Set<String> _registered = <String>{};

/// Embeds [url] in an HTML `<iframe>` sized to fill its parent box, surfaced
/// to Flutter web via [HtmlElementView]. Web-only — see `dashboard_embed.dart`.
Widget buildDashboardEmbed(String url) {
  final viewType = 'looker-embed-${url.hashCode}';
  if (_registered.add(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) => web.HTMLIFrameElement()
        ..src = url
        ..allowFullscreen = true
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%',
    );
  }
  return HtmlElementView(viewType: viewType);
}
