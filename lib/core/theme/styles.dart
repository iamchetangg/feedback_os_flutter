import 'package:flutter/material.dart';

/// Centralized text styles and typography for FeedbackOS SDK.
/// Mandated by project architecture rules.
abstract final class AppStyles {
  // Font Family
  static const String fontFamily = 'Roboto';

  // Headings
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: Color(0xFF111827),
  );

  static const TextStyle titleHeader = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: Color(0xFF1F2937),
  );

  static const TextStyle titleAppBar = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.5,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: Color(0xFF1F2937),
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: Color(0xFF1F2937),
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: Color(0xFF1F2937),
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Color(0xFF374151),
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Color(0xFF374151),
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Color(0xFF4B5563),
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Color(0xFF6B7280),
  );

  // Labels & Buttons
  static const TextStyle buttonPrimary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: Colors.white,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: Colors.white,
  );

  static const TextStyle tabLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Color(0xFF4B5563),
  );

  static const TextStyle tabLabelSelected = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Color(0xFF1F2937),
  );

  static const TextStyle chipLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Color(0xFF4B5563),
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Color(0xFF4B5563),
  );

  static const TextStyle meta = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    color: Color(0xFF6B7280),
  );

  static const TextStyle pillLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Color(0xFF9CA3AF),
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: Color(0xFF9CA3AF),
  );

  static const TextStyle stepperLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10.5,
    fontWeight: FontWeight.w500,
    color: Color(0xFF6B7280),
  );

  static const TextStyle stepperLabelActive = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
    color: Color(0xFF1D4ED8),
  );

  // Error & Helper
  static const TextStyle error = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Color(0xFFDC2626),
  );
}
