class CategoryUpdateRequest {
  String? name;
  String? description;

  CategoryUpdateRequest({
    this.name,
    this.description,
  });

  factory CategoryUpdateRequest.fromChangedFields({
    required String originalName,
    required String originalDescription,
    String? newName,
    String? newDescription,
  }) {
    final trimmedNewName = newName?.trim();
    final trimmedNewDescription = newDescription?.trim();

    return CategoryUpdateRequest(
      name: trimmedNewName != null && trimmedNewName != originalName.trim()
          ? trimmedNewName
          : null,
      description: trimmedNewDescription != null &&
              trimmedNewDescription != originalDescription.trim()
          ? trimmedNewDescription
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};

    if (name != null) {
      data['name'] = name;
    }

    if (description != null) {
      data['description'] = description;
    }

    return data;
  }
}