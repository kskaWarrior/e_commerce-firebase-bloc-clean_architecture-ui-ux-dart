import 'dart:async';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/bloc/button/button_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/bloc/button/button_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/navigator/app_navigator.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/widgets/my_app_bar.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/widgets/basic_reactive_button.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/assets/app_images.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_creation_req.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/usecases/signup.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/signin.dart';
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
  final String _typewriterText = 'Type your Address';

  int _currentChar = 0;
  Timer? _typewriterTimer;
  String _selectedGender = 'Male';
  DateTime? _selectedDate = DateTime(2000, 1, 1);

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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MyAppBar(
        title: 'Signing Up',
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
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is SuccessState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
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
            child: SingleChildScrollView(
              child: SizedBox(
                height: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    kToolbarHeight,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          textAlign: TextAlign.center,
                          'One step away from the best offers!',
                          style: TextStyle(
                            fontFamily: 'CircularStd',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 350,
                        child: Image.asset(
                          AppImages.oneStep,
                          width: 250,
                          height: 250,
                        ),
                      ),
                      const SizedBox(height: 40),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          textAlign: TextAlign.center,
                          'What gender of products are you most interested in?',
                          style: TextStyle(
                            fontFamily: 'CircularStd',
                            fontStyle: FontStyle.italic,
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
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
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                              fontFamily: 'CircularStd',
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
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                              fontFamily: 'CircularStd',
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
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                              fontFamily: 'CircularStd',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Born date picker
                      GestureDetector(
                        onTap: () => _pickDate(context),
                        child: Container(
                          width: 350,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.shade300,
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
                              const Icon(Icons.cake_outlined,
                                  color: Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedDate == null
                                      ? 'Select your birth date'
                                      : '${_selectedDate!.day.toString().padLeft(2, '0')}/'
                                          '${_selectedDate!.month.toString().padLeft(2, '0')}/'
                                          '${_selectedDate!.year}',
                                  style: const TextStyle(
                                    fontFamily: 'CircularStd',
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down,
                                  color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Address
                      SizedBox(
                        height: 55,
                        width: 350,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(16),
                          child: TextField(
                            controller: _addressController,
                            style: const TextStyle(
                              fontFamily: 'CircularStd',
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              hintText: _displayedAddress.isEmpty
                                  ? 'Type your Address'
                                  : _displayedAddress,
                              prefixIcon:
                                  const Icon(Icons.location_on_outlined),
                              filled: true,
                              fillColor: Colors.white,
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
                      const SizedBox(height: 40),
                      Builder(builder: (context) {
                        return BasicReactiveButton(
                            text: 'Sign Up',
                            onPressed: () {
                            if (_addressController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Please enter your address.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              widget.userCreationReq?.gender = _selectedGender;
                              widget.userCreationReq?.birthDate = _selectedDate;
                              widget.userCreationReq?.address =
                                  _addressController.text;
                              context.read<ButtonCubit>().execute(
                                  useCase: sl<SignupUseCase>(),
                                  params: widget.userCreationReq);
                            });
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
