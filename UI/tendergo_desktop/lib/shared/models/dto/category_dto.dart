import 'package:flutter/material.dart';

class CategoryDto {
  final int id;
  final String name;
  final String? description;
  final bool isActive;

  CategoryDto({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
  });

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    return CategoryDto(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'isActive': isActive,
    };
  }
}



// --- UI Theme logika za kategorije ---

class CategoryTheme {
  const CategoryTheme({required this.bg, required this.icon});
  final Color bg;
  final IconData icon;
}

/// Mapa koja povezuje nazive kategorija sa njihovim stilom
const Map<String, CategoryTheme> categoryThemes = {
  'Construction': CategoryTheme(bg: Color(0xFFE6F1FB), icon: Icons.construction_rounded),
  'IT & Software': CategoryTheme(bg: Color(0xFFEAF3DE), icon: Icons.laptop_mac_rounded),
  'Energy':        CategoryTheme(bg: Color(0xFFFAEEDA), icon: Icons.bolt_rounded),
  'Consulting':    CategoryTheme(bg: Color(0xFFEEEDFE), icon: Icons.menu_book_rounded),
  'Transport':     CategoryTheme(bg: Color(0xFFFBEAF0), icon: Icons.directions_car_rounded),
  'Healthcare':    CategoryTheme(bg: Color(0xFFE1F5EE), icon: Icons.local_hospital_rounded),
  'Education':     CategoryTheme(bg: Color(0xFFF1EFE8), icon: Icons.school_rounded),
  'Utilities':     CategoryTheme(bg: Color(0xFFFAECE7), icon: Icons.water_drop_rounded),
  'Supplies':      CategoryTheme(bg: Color(0xFFE6F1FB), icon: Icons.inventory_2_rounded),
};

/// Pomoćna funkcija za dobijanje teme. 
/// Ako kategorija ne postoji u mapi, vraća defaultnu sivu temu.
CategoryTheme themeForCategory(String categoryName) =>
    categoryThemes[categoryName] ??
    const CategoryTheme(bg: Color(0xFFF1EFE8), icon: Icons.description_rounded);


class CategoryStatisticsDto {
  final int categoryId;
  final String categoryName;
  final int tenderCount;
  final String description;
  final bool isActive;

  CategoryStatisticsDto({
    required this.categoryId,
    required this.categoryName,
    required this.tenderCount,
    required this.isActive,
    required this.description,
  });

  factory CategoryStatisticsDto.fromJson(Map<String, dynamic> json) {
    return CategoryStatisticsDto(
      categoryId: json['categoryId'] as int,
      categoryName: json['categoryName'] as String,
      tenderCount: json['tenderCount'] as int,
      description: json['description'] as String,
      isActive: json['isActive'] as bool,
    );
  }
}
