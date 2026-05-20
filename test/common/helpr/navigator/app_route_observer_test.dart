import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/navigator/app_route_observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('appRouteObserver is a RouteObserver', () {
    expect(appRouteObserver, isA<RouteObserver<ModalRoute<dynamic>>>());
  });
}
