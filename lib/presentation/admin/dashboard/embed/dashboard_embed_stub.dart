import 'package:flutter/widgets.dart';

/// Non-web placeholder. The admin dashboard is web-only, so this never
/// renders on mobile — it exists purely so the mobile build keeps compiling.
Widget buildDashboardEmbed(String url) => const SizedBox.shrink();
