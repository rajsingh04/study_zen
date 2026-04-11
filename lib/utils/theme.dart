import 'package:flutter/material.dart';

/// Central place for StudyZen colors and gradients so all
/// screens share a consistent look.
class AppColors {
  static const Color primary = Color(0xFF6B90AD);
  static const Color secondary = Color(0xFF81C39A);
  static const Color accent = Color(0xFF67B0A7);

  static const Color authBackgroundTop = Color(0xFFF8FBFB);
  static const Color authBackgroundBottom = Color(0xFFE2F1ED);

  static const Color scaffoldBackground = Color(0xFFEEF6F9);
}

const LinearGradient authBackgroundGradient = LinearGradient(
  colors: [AppColors.authBackgroundTop, AppColors.authBackgroundBottom],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient headerGradient = LinearGradient(
  colors: [Color(0xFF669DAB), AppColors.secondary],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient buttonGradient = LinearGradient(
  colors: [AppColors.primary, Color(0xFF86B599)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
