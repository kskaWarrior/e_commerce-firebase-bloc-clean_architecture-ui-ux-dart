import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/usecases/get_new_in_usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/bloc/new_in_display_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetNewInProductsUseCase extends Mock implements GetNewInProductsUseCase {}

void main() {
  test('can be instantiated', () {
    final cubit = NewInDisplayCubit(MockGetNewInProductsUseCase());

    expect(cubit, isA<NewInDisplayCubit>());

    cubit.close();
  });
}
