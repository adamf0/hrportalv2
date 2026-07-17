/// Base abstract class for all Domain Errors across modules in Clean Architecture.
abstract class DomainError implements Exception {
  final String message;
  const DomainError(this.message);

  @override
  String toString() => message;
}
