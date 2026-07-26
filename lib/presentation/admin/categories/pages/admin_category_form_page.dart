import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/i18n/app_strings.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/entities/categories_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/usecases/get_categories.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/usecases/upload_category_image_usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/usecases/upsert_category_usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class AdminCategoryFormPage extends StatefulWidget {
  const AdminCategoryFormPage({super.key, this.categoryId});

  final String? categoryId;

  @override
  State<AdminCategoryFormPage> createState() => _AdminCategoryFormPageState();
}

class _AdminCategoryFormPageState extends State<AdminCategoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  String _imageUrl = '';
  bool _loading = true;
  bool _saving = false;
  bool _uploading = false;

  bool get _isEdit => widget.categoryId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_isEdit) {
      final result = await sl<GetCategoriesUseCase>().call(null);
      result.fold(
        (_) {},
        (categories) {
          final match = List<CategoriesEntity>.from(categories)
              .where((c) => c.id == widget.categoryId)
              .toList();
          if (match.isNotEmpty) {
            _titleController.text = match.first.title;
            _imageUrl = match.first.image;
          }
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
    final result = await sl<UploadCategoryImageUseCase>().call(
      UploadCategoryImageParams(
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
      (url) => setState(() => _imageUrl = url.toString()),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final result = await sl<UpsertCategoryUseCase>().call({
      'id': widget.categoryId ?? '',
      'title': _titleController.text.trim(),
      'image': _imageUrl,
    });
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? s.editCategory : s.newCategory),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
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
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          if (_imageUrl.isNotEmpty &&
                              _imageUrl.startsWith('http'))
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Image.network(
                                _imageUrl,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image),
                              ),
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
                            _saving ? s.savingEllipsis : s.saveCategory),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
