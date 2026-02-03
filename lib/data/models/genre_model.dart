import 'package:flutter/material.dart';

class GenreModel {
  final int id;
  final String name;

  GenreModel({
    required this.id,
    required this.name,
  });

  factory GenreModel.fromJson(Map<String, dynamic> json) {
    return GenreModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  static Color getColorForGenre(int index) {
    final colors = [
      const Color(0xFF4A90E2),
      const Color(0xFF2C3E50),
      const Color(0xFF3498DB),
      const Color(0xFF34495E),
      const Color(0xFF8E44AD),
      const Color(0xFFE67E22),
      const Color(0xFF95A5A6),
      const Color(0xFF2C2C2C),
      const Color(0xFF16A085),
      const Color(0xFF27AE60),
      const Color(0xFFE91E63),
      const Color(0xFFFF5722),
      const Color(0xFF607D8B),
      const Color(0xFF795548),
      const Color(0xFF9C27B0),
      const Color(0xFF00BCD4),
      const Color(0xFF009688),
      const Color(0xFFFFC107),
      const Color(0xFFCDDC39),
    ];
    return colors[index % colors.length];
  }
}
