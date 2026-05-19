import 'dart:typed_data';

import 'package:dartz/dartz.dart' show Either;
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/widgets/my_app_bar.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_creation_req.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/entity/user_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/get_user.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/upload_profile_image.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/update_user.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  static const int _maxProfileImageBytes = 10 * 1024 * 1024;

  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String _selectedGender = 'Male';
  DateTime _selectedDate = DateTime(2000, 1, 1);
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  bool _obscurePassword = true;
  String _profileImageUrl = '';
  String _registeredEmail = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    final Either<Failure, UserEntity> result =
        await sl<GetUserUseCase>().call(null);

    if (!mounted) {
      return;
    }

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.error),
            backgroundColor: Colors.red,
          ),
        );
      },
      (user) {
        _nameController.text = user.name;
        _phoneController.text = user.phone;
        _emailController.text = user.email;
        _registeredEmail = user.email;
        _addressController.text = user.address;
        _selectedGender = user.gender.isNotEmpty ? user.gender : 'Male';
        _selectedDate = user.birthDate;
        _profileImageUrl = user.profileImageUrl;
      },
    );

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pickAndUploadProfileImage() async {
    final XFile? pickedImage =
        await _imagePicker.pickImage(source: ImageSource.gallery);

    if (pickedImage == null || !mounted) {
      return;
    }

    setState(() {
      _isUploadingImage = true;
    });

    final Uint8List imageBytes = await pickedImage.readAsBytes();
    if (imageBytes.lengthInBytes > _maxProfileImageBytes) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selected image is larger than 10 MB. Please choose a smaller file.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final String loweredName = pickedImage.name.toLowerCase();
    final String contentType = _guessContentType(loweredName);

    final Either<Failure, String> result =
        await sl<UploadProfileImageUseCase>()(
      UploadProfileImageParams(bytes: imageBytes, contentType: contentType),
    );

    if (!mounted) {
      return;
    }

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.error),
            backgroundColor: Colors.red,
          ),
        );
      },
      (uploadedUrl) {
        setState(() {
          _profileImageUrl = uploadedUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image updated successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      },
    );

    setState(() {
      _isUploadingImage = false;
    });
  }

  String _guessContentType(String fileName) {
    if (fileName.endsWith('.png')) {
      return 'image/png';
    }
    if (fileName.endsWith('.webp')) {
      return 'image/webp';
    }
    if (fileName.endsWith('.heic')) {
      return 'image/heic';
    }
    if (fileName.endsWith('.gif')) {
      return 'image/gif';
    }
    return 'image/jpeg';
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all editable fields.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final UserCreationReq params = UserCreationReq(
      email: _registeredEmail,
      password: _passwordController.text.trim().isEmpty
          ? null
          : _passwordController.text.trim(),
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      birthDate: _selectedDate,
      gender: _selectedGender,
    );

    final Either<Failure, String> result =
        await sl<UpdateUserUseCase>().call(params);

    if (!mounted) {
      return;
    }

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.error),
            backgroundColor: Colors.red,
          ),
        );
      },
      (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
      },
    );

    setState(() {
      _isSaving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double formWidth =
        (MediaQuery.sizeOf(context).width - 32).clamp(280.0, 420.0).toDouble();

    return Scaffold(
      appBar: const MyAppBar(
        title: 'My Profile',
        hideBack: false,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Center(
                  child: SizedBox(
                    width: formWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: (_isSaving || _isUploadingImage)
                                ? null
                                : _pickAndUploadProfileImage,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  radius: 52,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.15),
                                  backgroundImage: _profileImageUrl.isNotEmpty
                                      ? NetworkImage(_profileImageUrl)
                                      : null,
                                  child: _profileImageUrl.isEmpty
                                      ? const Icon(
                                          Icons.person,
                                          size: 52,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                Positioned(
                                  right: -2,
                                  bottom: -2,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                    child: _isUploadingImage
                                        ? const Padding(
                                            padding: EdgeInsets.all(8),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.camera_alt_outlined,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Tap to change photo',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'CircularStd',
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 22),
                        _ProfileInputField(
                          controller: _emailController,
                          labelText: 'Email',
                          hintText: 'Registered email (locked)',
                          icon: Icons.email_outlined,
                          suffixIcon: const Icon(Icons.lock_outline),
                          enabled: false,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 22),
                        _ProfileInputField(
                          controller: _nameController,
                          labelText: 'Name',
                          icon: Icons.person_outline,
                          keyboardType: TextInputType.name,
                        ),
                        const SizedBox(height: 22),
                        _ProfileInputField(
                          controller: _phoneController,
                          labelText: 'Phone',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 22),
                        _ProfileInputField(
                          controller: _passwordController,
                          labelText: 'Password',
                          hintText: 'New password (optional)',
                          icon: Icons.password_outlined,
                          keyboardType: TextInputType.visiblePassword,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 22),
                        _ProfileInputField(
                          controller: _addressController,
                          labelText: 'Address',
                          icon: Icons.location_on_outlined,
                          keyboardType: TextInputType.streetAddress,
                        ),
                        const SizedBox(height: 24),
                        const _ProfileSectionSeparator(),
                        const SizedBox(height: 24),
                        const Text(
                          'Most interested in products for:',
                          style: TextStyle(
                            fontFamily: 'CircularStd',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 14,
                          children: ['Male', 'Female', 'Both'].map((gender) {
                            final bool selected = _selectedGender == gender;
                            return ChoiceChip(
                              label: Text(gender),
                              selected: selected,
                              onSelected: (_) {
                                setState(() {
                                  _selectedGender = gender;
                                });
                              },
                              selectedColor:
                                  Theme.of(context).colorScheme.primary,
                              labelStyle: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                                fontFamily: 'CircularStd',
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        const _ProfileSectionSeparator(),
                        const SizedBox(height: 24),
                        Text(
                          'Birth Date',
                          style: _profileSectionLabelStyle(context),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.cake_outlined,
                                    color: Colors.grey),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${_selectedDate.day.toString().padLeft(2, '0')}/'
                                    '${_selectedDate.month.toString().padLeft(2, '0')}/'
                                    '${_selectedDate.year}',
                                    style: const TextStyle(
                                      fontFamily: 'CircularStd',
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down,
                                    color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const _ProfileSectionSeparator(),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              textStyle: const TextStyle(
                                fontFamily: 'CircularStd',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Save changes'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

TextStyle? _profileSectionLabelStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodySmall?.copyWith(
        fontFamily: 'CircularStd',
        fontSize: 17,
        fontWeight: FontWeight.w600,
      );
}

class _ProfileSectionSeparator extends StatelessWidget {
  const _ProfileSectionSeparator();

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.primary;

    return Container(
      height: 3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            baseColor.withValues(alpha: 0.0),
            baseColor.withValues(alpha: 0.22),
            baseColor.withValues(alpha: 0.85),
            baseColor.withValues(alpha: 0.22),
            baseColor.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
        ),
      ),
    );
  }
}

class _ProfileInputField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData icon;
  final TextInputType keyboardType;
  final bool enabled;
  final bool obscureText;
  final Widget? suffixIcon;

  const _ProfileInputField({
    required this.controller,
    required this.labelText,
    this.hintText = '',
    required this.icon,
    required this.keyboardType,
    this.enabled = true,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 55,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        child: TextField(
          controller: controller,
          enabled: enabled,
          obscureText: obscureText,
          style: const TextStyle(
            fontFamily: 'CircularStd',
            fontSize: 16,
          ),
          decoration: InputDecoration(
            labelText: labelText,
            labelStyle: _profileSectionLabelStyle(context),
            floatingLabelStyle: _profileSectionLabelStyle(context)?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            hintText: hintText,
            prefixIcon: Icon(icon),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey.shade200,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          keyboardType: keyboardType,
        ),
      ),
    );
  }
}
