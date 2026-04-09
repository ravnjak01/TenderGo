class ApiErrorHandler {

	static String? extractErrorMessage(dynamic data) {
  if (data == null) return null;

  try {
    //  backend šalje: {"errors": {"UserError": ["Poruka"], "ERROR": ["Poruka"]}}
    if (data is Map<String, dynamic> && data.containsKey('errors')) {
      var errors = data['errors'] as Map<String, dynamic>;

      if (errors.isNotEmpty) {
        // Uzimamo prvu listu grešaka (npr. UserError ili ERROR)
        var firstKey = errors.keys.first;
        var errorList = errors[firstKey] as List<dynamic>;

        if (errorList.isNotEmpty) {
          return errorList.first.toString();
        }
      }
    }
    
    // Fallback ako je format drugačiji (npr. direktna poruka)
    if (data is Map && data.containsKey('message')) {
      return data['message'];
    }
  } catch (e) {
    print("Error during parsing error message : $e");
  }

  return null;
}
}