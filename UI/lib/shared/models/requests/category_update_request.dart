class CategoryUpdateRequest {
  final String name;

  CategoryUpdateRequest({
    required this.name,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
  };
}