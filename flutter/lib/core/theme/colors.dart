import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF1565C0);
  static const primaryLight = Color(0xFF5E92F3);
  static const primaryDark = Color(0xFF003C8F);
  static const secondary = Color(0xFF00897B);
  static const secondaryLight = Color(0xFF4EBAAA);
  static const secondaryDark = Color(0xFF005B4F);
  static const error = Color(0xFFD32F2F);
  static const success = Color(0xFF388E3C);
  static const warning = Color(0xFFF57C00);

  static const backgroundLight = Color(0xFFF5F5F5);
  static const backgroundDark = Color(0xFF121212);
  static const surfaceLight = Colors.white;
  static const surfaceDark = Color(0xFF1E1E1E);

  static const Map<String, Color> categoryDefaults = {
    'Arbeit': Color(0xFF1565C0),
    'Familie': Color(0xFF388E3C),
    'Gesundheit': Color(0xFFD32F2F),
    'Einkauf': Color(0xFFF57C00),
    'Sonstiges': Color(0xFF757575),
  };

  static const List<Color> memberColors = [
    Color(0xFF1565C0),
    Color(0xFF388E3C),
    Color(0xFFD32F2F),
    Color(0xFFF57C00),
    Color(0xFF7B1FA2),
    Color(0xFF00897B),
    Color(0xFFC62828),
    Color(0xFF283593),
  ];

  static const List<Color> priorityColors = [
    Color(0xFF757575), // none
    Color(0xFF388E3C), // low
    Color(0xFFF57C00), // medium
    Color(0xFFD32F2F), // high
  ];
}
