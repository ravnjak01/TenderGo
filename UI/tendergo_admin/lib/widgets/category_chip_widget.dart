import 'package:flutter/material.dart';

class CategoryChipWidget extends StatelessWidget {

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const CategoryChipWidget({super.key,
  required this.label, required this.isSelected, required this.onTap
  });

  @override
  Widget build(BuildContext context) {
   return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF185FA5) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF185FA5) : const Color(0xFFE5E3DC),
            width: 1,
          ),
          boxShadow: isSelected 
            ? [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]
            : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF5F5E5A),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}