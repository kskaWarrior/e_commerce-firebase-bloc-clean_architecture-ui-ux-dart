import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/widgets/my_app_bar.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/user_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/user_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        title: 'Home Page',
        hideBack: true,
      ),
      body: BlocProvider(
        create: (context) => sl<UserCubit>()..getUser(),
        child: BlocListener<UserCubit, UserState>(
          listener: (context, state) {
            if (state is UserError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is UserLoaded) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Welcome, ${state.user.name}!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          //todo Usar blocbuilder para mostrar circular progress indicator enquanto
          //estiver carregando o usuário
          child: Center(
            child: Text(
              'Welcome to the Home Page!',
            ),
          ),
        ),
      ),
    );
  }
}

//USAR STATE HomeError.toString()