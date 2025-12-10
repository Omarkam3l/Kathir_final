class SupabaseHelperException implements Exception {
  final String message;
  SupabaseHelperException(this.message);
  @override
  String toString() => 'SupabaseHelperException: $message';
}
