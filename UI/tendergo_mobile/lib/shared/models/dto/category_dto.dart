import 'package:flutter/material.dart';

class CategoryDto {
  final int id;
  final String name;
  final bool isActive;

  CategoryDto({
    required this.id,
    required this.name,
    this.isActive = true,
  });

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    return CategoryDto(
      id: json['id'] as int,
      name: json['name'] as String,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isActive': isActive,
    };
  }
}




class CategoryTheme {
  const CategoryTheme({required this.bg, required this.icon});
  final Color bg;
  final IconData icon;
}

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

CategoryTheme themeForCategory(String categoryName) =>
    categoryThemes[categoryName] ??
    const CategoryTheme(bg: Color(0xFFF1EFE8), icon: Icons.description_rounded);
