import 'package:flutter/material.dart';

class MasterTheme {
  final Color primaryColor;
  final Color backgroundColor;
  final Color cardColor;
  final Color textColor;
  final Color secondaryTextColor;
  final Color borderColor;
  final Color successColor;
  final Color errorColor;
  final Color warningColor;

  MasterTheme({
    this.primaryColor = const Color(0xFF1E293B),
    this.backgroundColor = const Color(0xFFF8FAFC),
    this.cardColor = Colors.white,
    this.textColor = const Color(0xFF1E293B),
    this.secondaryTextColor = const Color(0xFF475569),
    this.borderColor = const Color(0xFFE2E8F0),
    this.successColor = Colors.green,
    this.errorColor = Colors.red,
    this.warningColor = Colors.amber,
  });

  // Predefined themes
  static final MasterTheme light = MasterTheme();

  static final MasterTheme blue = MasterTheme(
    primaryColor: const Color(0xFF2563EB),
    backgroundColor: const Color(0xFFF0F7FF),
  );

  static final MasterTheme green = MasterTheme(
    primaryColor: const Color(0xFF16A34A),
    backgroundColor: const Color(0xFFF0FDF4),
  );

  static final MasterTheme purple = MasterTheme(
    primaryColor: const Color(0xFF7C3AED),
    backgroundColor: const Color(0xFFF5F3FF),
  );

  MasterTheme copyWith({
    Color? primaryColor,
    Color? backgroundColor,
    Color? cardColor,
    Color? textColor,
    Color? secondaryTextColor,
    Color? borderColor,
    Color? successColor,
    Color? errorColor,
    Color? warningColor,
  }) {
    return MasterTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      cardColor: cardColor ?? this.cardColor,
      textColor: textColor ?? this.textColor,
      secondaryTextColor: secondaryTextColor ?? this.secondaryTextColor,
      borderColor: borderColor ?? this.borderColor,
      successColor: successColor ?? this.successColor,
      errorColor: errorColor ?? this.errorColor,
      warningColor: warningColor ?? this.warningColor,
    );
  }
}
