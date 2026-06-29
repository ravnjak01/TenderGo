class CategoryInsertRequest {
  final String name;
  final String description;

  CategoryInsertRequest({
    required this.name,
    required this.description,
  });

  String? validate() {
    if (name.trim().isEmpty) {
      return 'Naziv kategorije je obavezan.';
    }

    if (description.trim().isEmpty) {
      return 'Opis kategorije je obavezan.';
    }

    return null;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
      };
}