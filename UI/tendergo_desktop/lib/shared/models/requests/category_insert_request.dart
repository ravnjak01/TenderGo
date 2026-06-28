class CategoryInsertRequest {
  final String name;
  final String description;

  CategoryInsertRequest({
    required this.name,
    required this.description
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description':description
  };
}