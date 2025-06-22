class Failure {

  final String error;
  Failure({required this.error});

  @override
  String toString() {
    return 'error: $error';
  }
}