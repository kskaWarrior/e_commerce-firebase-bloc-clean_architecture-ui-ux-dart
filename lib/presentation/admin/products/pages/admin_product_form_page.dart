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
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/admin/widgets/admin_color_picker.dart';
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
    final s = S.of(context);
    final initial = index != null ? _colors[index] : null;
    final result = await showAdminColorPicker(
      context,
      title: initial == null ? s.addColor : s.editColor,
      initialHex: initial?.hex ?? '1C1C1C',
      initialName: initial?.title ?? '',
    );
    if (result == null || !mounted) return;
    setState(() {
      final item = _ColorItem(result.name, result.hex);
      if (index != null) {
        _colors[index] = item;
      } else {
        _colors.add(item);
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
                color: adminHexToColor(item.hex),
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
