import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/i18n/app_strings.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/admin/theme/admin_theme.dart';
import 'package:flutter/material.dart';

/// Result of the admin color picker: a 6-digit `RRGGBB` [hex] (uppercase, no
/// '#') and an optional [name].
class AdminColorPickResult {
  const AdminColorPickResult(this.hex, this.name);

  final String hex;
  final String name;
}

/// Resolves a stored hex (6- or 8-digit, with or without '#') to an opaque
/// Color — the leading alpha of an 8-digit value is ignored.
Color adminHexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '').trim();
  final six = cleaned.length >= 6
      ? cleaned.substring(cleaned.length - 6)
      : cleaned.padLeft(6, '0');
  final value = int.tryParse(six, radix: 16) ?? 0;
  return Color(0xFF000000 | value);
}

/// Opens the visual color picker (2D saturation/value map + hue bar + HEX
/// field + R/G/B sliders + preset swatches), all kept in sync.
///
/// [initialHex] may be 6- or 8-digit; only the RGB is edited. Set [withName]
/// to false to hide the name field (e.g. for theme colors). [title] is the
/// dialog heading. Returns null if cancelled.
Future<AdminColorPickResult?> showAdminColorPicker(
  BuildContext context, {
  required String title,
  String initialHex = '1C1C1C',
  String initialName = '',
  bool withName = true,
}) {
  return showDialog<AdminColorPickResult>(
    context: context,
    builder: (_) => _AdminColorPickerDialog(
      title: title,
      initialHex: initialHex,
      initialName: initialName,
      withName: withName,
    ),
  );
}

class _AdminColorPickerDialog extends StatefulWidget {
  const _AdminColorPickerDialog({
    required this.title,
    required this.initialHex,
    required this.initialName,
    required this.withName,
  });

  final String title;
  final String initialHex;
  final String initialName;
  final bool withName;

  @override
  State<_AdminColorPickerDialog> createState() =>
      _AdminColorPickerDialogState();
}

class _AdminColorPickerDialogState extends State<_AdminColorPickerDialog> {
  static const List<(String, String)> _presets = [
    ('Black', '1C1C1C'), ('White', 'F5F5F5'), ('Gray', '9E9E9E'),
    ('Navy', '0A2035'), ('Blue', '2563EB'), ('Sky', '38BDF8'),
    ('Teal', '0D9488'), ('Green', '16A34A'), ('Lime', '84CC16'),
    ('Yellow', 'FEBD2E'), ('Orange', 'F97316'), ('Red', 'E11D48'),
    ('Pink', 'EC4899'), ('Purple', '7C3AED'), ('Brown', '8B5E3C'),
    ('Beige', 'E8D9C0'),
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _hexController;
  // HSV is the source of truth so the hue/map interactions preserve hue even
  // at zero saturation/value (grey/black); RGB + hex derive from it.
  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _hsv = HSVColor.fromColor(adminHexToColor(widget.initialHex));
    _hexController = TextEditingController(text: _hex);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hexController.dispose();
    super.dispose();
  }

  Color get _color => _hsv.toColor();
  int get _r => _color.red;
  int get _g => _color.green;
  int get _b => _color.blue;

  String get _hex =>
      _r.toRadixString(16).padLeft(2, '0').toUpperCase() +
      _g.toRadixString(16).padLeft(2, '0').toUpperCase() +
      _b.toRadixString(16).padLeft(2, '0').toUpperCase();

  void _setHsv(HSVColor hsv, {bool updateHexField = true}) {
    setState(() => _hsv = hsv);
    if (updateHexField) _hexController.text = _hex;
  }

  void _applyHex(String raw, {bool updateField = true}) {
    final cleaned = raw.replaceAll('#', '').trim();
    if (cleaned.length != 6) return;
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return;
    _setHsv(HSVColor.fromColor(Color(0xFF000000 | value)),
        updateHexField: updateField);
  }

  void _setChannel({int? r, int? g, int? b}) {
    _setHsv(HSVColor.fromColor(
        Color.fromARGB(255, r ?? _r, g ?? _g, b ?? _b)));
  }

  void _selectPreset(String name, String hex) {
    if (widget.withName && _nameController.text.trim().isEmpty) {
      _nameController.text = name;
    }
    _setHsv(HSVColor.fromColor(adminHexToColor(hex)));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 168,
                  width: double.infinity,
                  child: _SvMap(
                    hsv: _hsv,
                    onChanged: (sat, val) =>
                        _setHsv(_hsv.withSaturation(sat).withValue(val)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _HueBar(
                hue: _hsv.hue,
                onChanged: (hue) => _setHsv(_hsv.withHue(hue)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AdminColors.border),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: _hexController,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: s.colorValueHex,
                        prefixText: '#',
                        counterText: '',
                      ),
                      onChanged: (v) => _applyHex(v, updateField: false),
                    ),
                  ),
                ],
              ),
              if (widget.withName) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: s.colorName),
                ),
              ],
              const SizedBox(height: 14),
              _channelSlider(
                  'R', _r, AdminColors.cancelled, (v) => _setChannel(r: v)),
              _channelSlider(
                  'G', _g, AdminColors.delivered, (v) => _setChannel(g: v)),
              _channelSlider(
                  'B', _b, AdminColors.paid, (v) => _setChannel(b: v)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final preset in _presets)
                    _PresetSwatch(
                      color: adminHexToColor(preset.$2),
                      selected: _hex == preset.$2,
                      onTap: () => _selectPreset(preset.$1, preset.$2),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            AdminColorPickResult(_hex, _nameController.text.trim()),
          ),
          child: Text(s.saveChanges),
        ),
      ],
    );
  }

  Widget _channelSlider(
      String label, int value, Color color, ValueChanged<int> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 18,
          child:
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 255,
            activeColor: color,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        SizedBox(
          width: 34,
          child: Text('$value', textAlign: TextAlign.right),
        ),
      ],
    );
  }
}

/// The 2D saturation (x) / value (y) map for the current hue. Drag anywhere —
/// the ring acts as the color dropper.
class _SvMap extends StatelessWidget {
  const _SvMap({required this.hsv, required this.onChanged});

  final HSVColor hsv;
  final void Function(double sat, double val) onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        void handle(Offset p) {
          final sat = (p.dx / w).clamp(0.0, 1.0);
          final val = 1 - (p.dy / h).clamp(0.0, 1.0);
          onChanged(sat, val);
        }

        final hueColor = HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor();
        return GestureDetector(
          onPanDown: (d) => handle(d.localPosition),
          onPanUpdate: (d) => handle(d.localPosition),
          child: Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: hueColor)),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Colors.white, Color(0x00FFFFFF)],
                    ),
                  ),
                ),
              ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Colors.black],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: (hsv.saturation * w).clamp(0.0, w) - 9,
                top: ((1 - hsv.value) * h).clamp(0.0, h) - 9,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.45), blurRadius: 3),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Horizontal hue spectrum; drag the thumb to rotate the hue.
class _HueBar extends StatelessWidget {
  const _HueBar({required this.hue, required this.onChanged});

  final double hue;
  final ValueChanged<double> onChanged;

  static const List<Color> _spectrum = [
    Color(0xFFFF0000),
    Color(0xFFFFFF00),
    Color(0xFF00FF00),
    Color(0xFF00FFFF),
    Color(0xFF0000FF),
    Color(0xFFFF00FF),
    Color(0xFFFF0000),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final width = c.maxWidth;
        void handle(double dx) =>
            onChanged((dx / width * 360).clamp(0.0, 360.0));
        return GestureDetector(
          onPanDown: (d) => handle(d.localPosition.dx),
          onPanUpdate: (d) => handle(d.localPosition.dx),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 16,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(colors: _spectrum),
                ),
              ),
              Positioned(
                left: (hue / 360 * width).clamp(0.0, width) - 9,
                top: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.35), blurRadius: 3),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PresetSwatch extends StatelessWidget {
  const _PresetSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AdminColors.accent : AdminColors.border,
            width: selected ? 2.4 : 1,
          ),
        ),
      ),
    );
  }
}
