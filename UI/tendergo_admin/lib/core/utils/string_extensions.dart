
  extension StringExtensions on String {
  String toRoleLabel() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}



