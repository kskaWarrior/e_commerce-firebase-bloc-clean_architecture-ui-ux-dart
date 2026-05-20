import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/entities/sales_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/usecases/get_sales_by_user_id.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/sales/bloc/get_sales_by_user_id_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/sales/bloc/get_sales_by_user_id_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetSalesByUserIdUseCase extends Mock implements GetSalesByUserIdUseCase {}

void main() {
  late MockGetSalesByUserIdUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockGetSalesByUserIdUseCase();
  });

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

  blocTest<GetSalesByUserIdCubit, GetSalesByUserIdState>(
    'emits [Loading, Loaded] when sales load succeeds',
    build: () {
      when(() => mockUseCase.call('u1'))
          .thenAnswer((_) async => Right([buildSale()]));
      return GetSalesByUserIdCubit(getSalesByUserIdUseCase: mockUseCase);
    },
    act: (cubit) => cubit.getSalesByUserId('u1'),
    expect: () => [
      isA<GetSalesByUserIdLoading>(),
      isA<GetSalesByUserIdLoaded>()
          .having((state) => state.sales.length, 'sales length', 1),
    ],
  );

  blocTest<GetSalesByUserIdCubit, GetSalesByUserIdState>(
    'emits [Loading, Error] when sales load fails',
    build: () {
      when(() => mockUseCase.call('u1'))
          .thenAnswer((_) async => Left(Failure(error: 'db')));
      return GetSalesByUserIdCubit(getSalesByUserIdUseCase: mockUseCase);
    },
    act: (cubit) => cubit.getSalesByUserId('u1'),
    expect: () => [
      isA<GetSalesByUserIdLoading>(),
      isA<GetSalesByUserIdError>()
          .having((state) => state.message, 'message', 'error: db'),
    ],
  );
}
