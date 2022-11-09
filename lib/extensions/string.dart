extension StringExtension on String {
  /// Returns string with capitalized first letter
  ///
  /// Example:
  /// ```dart
  /// assert('test'.capitalizeFirstLetter(), 'Test');
  /// ```
  String capitalizeFirstLetter() =>
      isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : this;

}