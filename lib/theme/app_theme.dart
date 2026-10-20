import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Safety-themed Material 3 palette (inspired by DeepCrash dashboard colours).
abstract final class AppColors {
  static const Color brand = Color(0xFF0B3A5B);
  static const Color page = Color(0xFFF3F5F8);
  static const Color safe = Color(0xFF1B7F4E);
  static const Color emergency = Color(0xFFC62828);
  static const Color warning = Color(0xFFE65100);
  static const Color accent = Color(0xFF1565C0);
}

abstract final class AppMetrics {
  static const double page = 16;
  static const double gap = 12;
  static const double radius = 16;
}

abstract final class AppTheme {
  static const Color _seed = Color(0xFF0C447C);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    );
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.page,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppMetrics.radius),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
