import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/entities/sales_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/usecases/register_sale.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/sales/bloc/register_sale_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/sales/bloc/register_sale_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRegisterSaleUseCase extends Mock implements RegisterSaleUseCase {}

class FakeSalesEntity extends Fake implements SalesEntity {}

void main() {
  late MockRegisterSaleUseCase mockUseCase;

  SalesEntity buildSale() {
    final ts = Timestamp.fromDate(DateTime(2025, 1, 1));
    return SalesEntity(
      createdDate: ts,
      discountedPrice: 100,
      freight: 10,
      id: 's1',
      installmentsNumber: 1,
      paymentMethod: 'pix',
      price: 110,
      productsList: const [],
      totalPrice: 110,
      userBirthDate: ts,
      userGender: 'male',
      userId: 'u1',
      userName: 'John',
    );
  }

  setUp(() {
    registerFallbackValue(FakeSalesEntity());
    mockUseCase = MockRegisterSaleUseCase();
  });

  blocTest<RegisterSaleCubit, RegisterSaleState>(
    'emits [RegisterSaleLoading, RegisterSaleSuccess] when register succeeds',
    build: () {
      when(() => mockUseCase.call(any()))
          .thenAnswer((_) async => const Right('sale created'));
      return RegisterSaleCubit(registerSaleUseCase: mockUseCase);
    },
    act: (cubit) => cubit.registerSale(buildSale()),
    expect: () => [
      isA<RegisterSaleLoading>(),
      isA<RegisterSaleSuccess>()
          .having((state) => state.message, 'message', 'sale created'),
    ],
  );

  blocTest<RegisterSaleCubit, RegisterSaleState>(
    'emits [RegisterSaleLoading, RegisterSaleFailure] when register fails',
    build: () {
      when(() => mockUseCase.call(any()))
          .thenAnswer((_) async => Left(Failure(error: 'error')));
      return RegisterSaleCubit(registerSaleUseCase: mockUseCase);
    },
    act: (cubit) => cubit.registerSale(buildSale()),
    expect: () => [
      isA<RegisterSaleLoading>(),
      isA<RegisterSaleFailure>()
          .having((state) => state.message, 'message', 'error: error'),
    ],
  );
}
