import 'dart:async';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/button_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/button_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/navigator/app_navigator.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/widgets/my_app_bar.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/widgets/basic_reactive_button.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/assets/app_images.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/theme/brand_tokens.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/i18n/app_strings.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_creation_req.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/signup.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/signin.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/web/widgets/web_auth_frame.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GenderAndAgePage extends StatefulWidget {
  final UserCreationReq? userCreationReq;

  const GenderAndAgePage({
    super.key,
    required this.userCreationReq
  });

  @override
  State<GenderAndAgePage> createState() => _GenderAndAgePageState();
}

class _GenderAndAgePageState extends State<GenderAndAgePage> {
  final TextEditingController _addressController = TextEditingController();

  // Typewriter state for each field
  String get _typewriterText => S.of(context).typeYourAddress;

  int _currentChar = 0;
  Timer? _typewriterTimer;
  String _selectedGender = 'Male';
  DateTime? _selectedDate = DateTime(2000, 1, 1);
  static const int _minimumAge = 12;

  @override
  void initState() {
    super.initState();
    _startTypewriter();
  }

  // ignore: unused_field
  String _displayedAddress = '';

  void _startTypewriter() {
    _typewriterTimer?.cancel();
    _currentChar = 0;
    _displayedAddress = '';
    _typewriterTimer =
        Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_currentChar < _typewriterText.length) {
        setState(() {
          _displayedAddress += _typewriterText[_currentChar];
          _currentChar++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final latestAllowedBirthDate =
        DateTime(now.year - _minimumAge, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate != null &&
              _selectedDate!.isBefore(latestAllowedBirthDate)
          ? _selectedDate
          : latestAllowedBirthDate,
      firstDate: DateTime(1900),
      lastDate: latestAllowedBirthDate,
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  bool _isAtLeastMinimumAge(DateTime birthDate) {
    final now = DateTime.now();
    var age = now.year - birthDate.year;

    final hasNotHadBirthdayThisYear = now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day);

    if (hasNotHadBirthdayThisYear) {
      age--;
    }

    return age >= _minimumAge;
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // On web, the untouched mobile layout renders inside a centered glass
    // panel over a branded backdrop (see WebAuthFrame).
    return WebAuthFrame.wrap(_buildMobileLayout(context));
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        title: S.of(context).signingUp,
        hideBack: false,
      ),
      resizeToAvoidBottomInset: true,
      body: BlocProvider(
        create: (context) => ButtonCubit(),
        child: BlocListener<ButtonCubit, ButtonState>(
          listener: (context, state) {
            if (state is FailureState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: context.brand.danger,
                ),
              );
            } else if (state is SuccessState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: context.brand.success,
                ),
              );
              // Navigate to SigninPage on success
              AppNavigator.pushReplacement(
                context,
                const SigninPage(),
              );
            }
          },
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = MediaQuery.sizeOf(context).width;
                final formWidth =
                    (screenWidth - 32).clamp(280.0, 420.0).toDouble();
                final illustrationSize =
                    (screenWidth * 0.6).clamp(180.0, 260.0).toDouble();

                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 40.0),
                        child: Text(
                          textAlign: TextAlign.center,
                              S.of(context).oneStepAway,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                            width: formWidth,
                        child: Image.asset(
                          AppImages.oneStep,
                              width: illustrationSize,
                              height: illustrationSize,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          textAlign: TextAlign.center,
                          S.of(context).whatGenderInterested,
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Gender selection buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('Male'),
                            selected: _selectedGender == 'Male',
                            onSelected: (selected) {
                              setState(() {
                                _selectedGender = 'Male';
                              });
                            },
                            selectedColor:
                                Theme.of(context).colorScheme.primary,
                            labelStyle: TextStyle(
                              color: _selectedGender == 'Male'
                                  ? context.brand.textInverse
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ChoiceChip(
                            label: const Text('Female'),
                            selected: _selectedGender == 'Female',
                            onSelected: (selected) {
                              setState(() {
                                _selectedGender = 'Female';
                              });
                            },
                            selectedColor:
                                Theme.of(context).colorScheme.primary,
                            labelStyle: TextStyle(
                              color: _selectedGender == 'Female'
                                  ? context.brand.textInverse
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ChoiceChip(
                            label: const Text('Both'),
                            selected: _selectedGender == 'Both',
                            onSelected: (selected) {
                              setState(() {
                                _selectedGender = 'Both';
                              });
                            },
                            selectedColor:
                                Theme.of(context).colorScheme.primary,
                            labelStyle: TextStyle(
                              color: _selectedGender == 'Both'
                                  ? context.brand.textInverse
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Born date picker
                      GestureDetector(
                        onTap: () => _pickDate(context),
                        child: Container(
                              width: formWidth,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          decoration: BoxDecoration(
                            color: context.brand.surfaceBright,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: context.brand.mutedSoft,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.cake_outlined,
                                  color: context.brand.muted),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedDate == null
                                      ? S.of(context).selectYourBirthDate
                                      : '${_selectedDate!.day.toString().padLeft(2, '0')}/'
                                          '${_selectedDate!.month.toString().padLeft(2, '0')}/'
                                          '${_selectedDate!.year}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Icon(Icons.arrow_drop_down,
                                  color: context.brand.muted),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Address
                      SizedBox(
                        height: 55,
                            width: formWidth,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(16),
                          child: TextField(
                            controller: _addressController,
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              hintText: _displayedAddress.isEmpty
                                  ? S.of(context).typeYourAddress
                                  : _displayedAddress,
                              prefixIcon:
                                  const Icon(Icons.location_on_outlined),
                              filled: true,
                              fillColor: context.brand.surfaceBright,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 20, horizontal: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            keyboardType: TextInputType.streetAddress,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Builder(builder: (context) {
                            return SizedBox(
                              width: formWidth,
                              child: BasicReactiveButton(
                                  text: S.of(context).signUpButton,
                                  onPressed: () {
                                    if (_addressController.text.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(S
                                              .of(context)
                                              .pleaseEnterAddress),
                                          backgroundColor:
                                              context.brand.danger,
                                        ),
                                      );
                                      return;
                                    }

                                    if (_selectedDate == null ||
                                        !_isAtLeastMinimumAge(_selectedDate!)) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            S.of(context).mustBeAtLeastTwelve,
                                          ),
                                          backgroundColor:
                                              context.brand.danger,
                                        ),
                                      );
                                      return;
                                    }

                                    widget.userCreationReq?.gender =
                                        _selectedGender;
                                    widget.userCreationReq?.birthDate =
                                        _selectedDate;
                                    widget.userCreationReq?.address =
                                        _addressController.text;
                                    context.read<ButtonCubit>().execute(
                                        useCase: sl<SignupUseCase>(),
                                        params: widget.userCreationReq);
                                  }),
                            );
                      }),
                    ],
                  ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
