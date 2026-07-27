import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/i18n/app_strings.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/entities/categories_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/usecases/get_categories.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/product_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/usecases/get_product_by_id_usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/usecases/upload_product_image_usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/usecases/upsert_product_usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/widgets/web_image_viewer.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/theme/brand_tokens.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/admin/theme/admin_theme.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class AdminProductFormPage extends StatefulWidget {
  const AdminProductFormPage({super.key, this.productId});

  final String? productId;

  @override
  State<AdminProductFormPage> createState() => _AdminProductFormPageState();
}

class _AdminProductFormPageState extends State<AdminProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountedPriceController = TextEditingController();
  final _sizesController = TextEditingController();
  final List<_ColorItem> _colors = [];

  List<CategoriesEntity> _categories = [];
  String? _categoryId;
  String _gender = 'unisex';
  final List<String> _imageUrls = [];
  ProductEntity? _existing;
  bool _loading = true;
  bool _saving = false;
  bool _uploading = false;

  bool get _isEdit => widget.productId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final categoriesResult = await sl<GetCategoriesUseCase>().call(null);
    categoriesResult.fold(
      (_) {},
      (categories) =>
          _categories = List<CategoriesEntity>.from(categories),
    );

    if (_isEdit) {
      final productResult =
          await sl<GetProductByIdUseCase>().call(widget.productId!);
      productResult.fold(
        (_) {},
        (product) {
          final p = product as ProductEntity;
          _existing = p;
          _titleController.text = p.title;
          _descriptionController.text = p.description;
          _priceController.text = p.price.toString();
          _discountedPriceController.text = p.discountedPrice.toString();
          _sizesController.text = p.sizes.join(', ');
          _colors
            ..clear()
            ..addAll(p.colors
                .map((c) => _ColorItem(c.title, _normalizeHex(c.hexCode))));
          _categoryId = p.categoryId.isEmpty ? null : p.categoryId;
          _gender = p.gender.isEmpty ? 'unisex' : p.gender;
          _imageUrls.addAll(p.images.map((e) => e.toString()));
        },
      );
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _uploading = true);
    final bytes = await picked.readAsBytes();
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
    final result = await sl<UploadProductImageUseCase>().call(
      UploadProductImageParams(
        bytes: bytes,
        contentType: picked.mimeType ?? 'image/png',
        fileName: fileName,
      ),
    );
    if (!mounted) return;
    setState(() => _uploading = false);
    result.fold(
      (error) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString()))),
      (url) => setState(() => _imageUrls.add(url.toString())),
    );
  }

  /// 6-digit uppercase RRGGBB (drops any leading alpha and the '#').
  static String _normalizeHex(String raw) {
    final cleaned = raw.replaceAll('#', '').trim().toUpperCase();
    if (cleaned.length >= 6) {
      return cleaned.substring(cleaned.length - 6);
    }
    return cleaned.padLeft(6, '0');
  }

  List<Map<String, String>> _parseColors() {
    return _colors
        .where((c) => c.hex.isNotEmpty)
        .map((c) => {'title': c.title.trim(), 'hexCode': c.hex})
        .toList();
  }

  Future<void> _editColor({int? index}) async {
    final result = await showDialog<_ColorItem>(
      context: context,
      builder: (_) => _ColorPickerDialog(
        initial: index != null ? _colors[index] : null,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (index != null) {
        _colors[index] = result;
      } else {
        _colors.add(result);
      }
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).pleaseChooseCategory)));
      return;
    }

    setState(() => _saving = true);

    final price = num.tryParse(_priceController.text) ?? 0;
    final discounted =
        num.tryParse(_discountedPriceController.text) ?? price;
    final category = _categories.firstWhere((c) => c.id == _categoryId,
        orElse: () => CategoriesEntity(id: _categoryId!, title: '', image: ''));

    final product = <String, dynamic>{
      'id': _existing?.id ?? '',
      'productId': _existing?.productId ?? '',
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': price,
      'discountedPrice': discounted,
      'currentDiscount':
          price > 0 ? (((price - discounted) / price) * 100).round() : 0,
      'categoryId': _categoryId,
      'categoryName': category.title,
      'gender': _gender,
      'sizes': _sizesController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      'colors': _parseColors(),
      'images': _imageUrls,
      if (_existing != null) 'createdDate': _existing!.createdDate,
      if (_existing != null) 'salesNumber': _existing!.salesNumber,
    };

    final result = await sl<UpsertProductUseCase>().call(product);
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      (error) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString()))),
      (_) => context.pop(),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountedPriceController.dispose();
    _sizesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? s.editProduct : s.newProduct),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration:
                            InputDecoration(labelText: s.title),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? s.titleRequired
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        decoration:
                            InputDecoration(labelText: s.description),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              decoration:
                                  InputDecoration(labelText: s.price),
                              keyboardType: TextInputType.number,
                              validator: (v) =>
                                  num.tryParse(v ?? '') == null
                                      ? s.enterValidPrice
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _discountedPriceController,
                              decoration: InputDecoration(
                                  labelText: s.discountedPriceOptional),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _categoryId,
                              decoration: InputDecoration(
                                  labelText: s.categoryFallback),
                              items: [
                                for (final category in _categories)
                                  DropdownMenuItem(
                                    value: category.id,
                                    child: Text(category.title),
                                  ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _categoryId = value),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _gender,
                              decoration:
                                  InputDecoration(labelText: s.gender),
                              items: [
                                DropdownMenuItem(
                                    value: 'unisex',
                                    child: Text(s.genderUnisex)),
                                DropdownMenuItem(
                                    value: 'men', child: Text(s.genderMen)),
                                DropdownMenuItem(
                                    value: 'women',
                                    child: Text(s.genderWomen)),
                              ],
                              onChanged: (value) => setState(
                                  () => _gender = value ?? 'unisex'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _sizesController,
                        decoration: InputDecoration(
                          labelText: s.sizes,
                          hintText: s.sizesHint,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(s.colors,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          for (var i = 0; i < _colors.length; i++)
                            _ColorChip(
                              item: _colors[i],
                              onEdit: () => _editColor(index: i),
                              onDelete: () =>
                                  setState(() => _colors.removeAt(i)),
                            ),
                          OutlinedButton.icon(
                            onPressed: () => _editColor(),
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(s.addColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(s.images,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var i = 0; i < _imageUrls.length; i++)
                            Stack(
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.zoomIn,
                                  child: GestureDetector(
                                    onTap: () => showWebImageViewer(
                                      context,
                                      imagePaths: _imageUrls,
                                      initialIndex: i,
                                    ),
                                    child: Image.network(
                                      _imageUrls[i],
                                      width: 96,
                                      height: 96,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 96,
                                        height: 96,
                                        color: Colors.black12,
                                        child: const Icon(Icons.broken_image),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: IconButton(
                                    icon: Icon(Icons.cancel,
                                        size: 20,
                                        color: context.brand.danger),
                                    onPressed: () => setState(
                                        () => _imageUrls.removeAt(i)),
                                  ),
                                ),
                              ],
                            ),
                          OutlinedButton.icon(
                            onPressed:
                                _uploading ? null : _pickAndUploadImage,
                            icon: _uploading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.upload),
                            label: Text(s.uploadImage),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        child: Text(
                            _saving ? s.savingEllipsis : s.saveProduct),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

/// A single editable product color: a display name plus a 6-digit RRGGBB
/// hex (uppercase, no leading '#').
class _ColorItem {
  _ColorItem(this.title, this.hex);
  String title;
  String hex;
}

Color _hexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '').trim();
  final six = cleaned.length >= 6
      ? cleaned.substring(cleaned.length - 6)
      : cleaned.padLeft(6, '0');
  final value = int.tryParse(six, radix: 16) ?? 0;
  return Color(0xFF000000 | value);
}

/// Read-only swatch chip shown in the form; tap opens the editor, X removes.
class _ColorChip extends StatelessWidget {
  const _ColorChip({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final _ColorItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
        decoration: BoxDecoration(
          color: AdminColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AdminColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _hexToColor(item.hex),
                shape: BoxShape.circle,
                border: Border.all(color: AdminColors.border),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              item.title.trim().isEmpty ? '#${item.hex}' : item.title,
              style:
                  const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: onDelete,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(3),
                child: Icon(Icons.close,
                    size: 15, color: AdminColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Visual color editor: preset swatches, a HEX field, and R/G/B sliders,
/// all kept in sync with a live preview. Returns a [_ColorItem] on save.
class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({this.initial});

  final _ColorItem? initial;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
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
  int _r = 28, _g = 28, _b = 28;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.title ?? '');
    final hex = widget.initial?.hex ?? '1C1C1C';
    _hexController = TextEditingController(text: hex);
    _applyHex(hex, updateField: false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hexController.dispose();
    super.dispose();
  }

  String get _hex =>
      _r.toRadixString(16).padLeft(2, '0').toUpperCase() +
      _g.toRadixString(16).padLeft(2, '0').toUpperCase() +
      _b.toRadixString(16).padLeft(2, '0').toUpperCase();

  /// Parse a 6-digit hex into the R/G/B channels. Only rewrites the text
  /// field when [updateField] is set (avoids fighting the user's cursor).
  void _applyHex(String raw, {bool updateField = true}) {
    final cleaned = raw.replaceAll('#', '').trim();
    if (cleaned.length != 6) return;
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return;
    setState(() {
      _r = (value >> 16) & 0xFF;
      _g = (value >> 8) & 0xFF;
      _b = value & 0xFF;
    });
    if (updateField) {
      final upper = cleaned.toUpperCase();
      _hexController.value = TextEditingValue(
        text: upper,
        selection: TextSelection.collapsed(offset: upper.length),
      );
    }
  }

  void _setChannel(VoidCallback apply) {
    setState(apply);
    _hexController.text = _hex;
  }

  void _selectPreset(String name, String hex) {
    if (_nameController.text.trim().isEmpty) {
      _nameController.text = name;
    }
    _applyHex(hex);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final preview = Color(0xFF000000 | (_r << 16) | (_g << 8) | _b);

    return AlertDialog(
      title: Text(widget.initial == null ? s.addColor : s.editColor),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: preview,
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
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: s.colorName),
              ),
              const SizedBox(height: 14),
              _channelSlider(
                  'R', _r, AdminColors.cancelled, (v) => _setChannel(() => _r = v)),
              _channelSlider(
                  'G', _g, AdminColors.delivered, (v) => _setChannel(() => _g = v)),
              _channelSlider(
                  'B', _b, AdminColors.paid, (v) => _setChannel(() => _b = v)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final preset in _presets)
                    _PresetSwatch(
                      color: _hexToColor(preset.$2),
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
            _ColorItem(_nameController.text.trim(), _hex),
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
