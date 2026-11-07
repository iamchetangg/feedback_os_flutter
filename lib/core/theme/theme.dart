import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Runtime constants and user-defined theming for the FeedbackOS Flutter SDK.
///
/// Propagates colors and styles to all FeedbackOS widgets without forcing colors.
/// If user colors are not provided, sensible defaults are used as fallbacks.
class FeedbackOSTheme extends Equatable {
  // Default Fallback Color Constants
  static const Color defaultPrimaryColor = Color(0xFF4F46E5);
  static const Color defaultPrimaryLightColor = Color(0xFFEEF2FF);
  static const Color defaultPrimaryDarkColor = Color(0xFF4338CA);
  static const Color defaultPrimaryLightBorderColor = Color(0xFFC7D2FE);
  static const Color defaultOnPrimaryColor = Colors.white;
  static const Color defaultBackgroundColor = Color(0xFFF9FAFB);
  static const Color defaultSurfaceColor = Colors.white;
  static const Color defaultSecondaryBackgroundColor = Color(0xFFF3F4F6);
  static const Color defaultBorderColor = Color(0xFFE5E7EB);
  static const Color defaultBorderMutedColor = Color(0xFFD1D5DB);
  static const Color defaultTitleColor = Color(0xFF111827);
  static const Color defaultTextColor = Color(0xFF1F2937);
  static const Color defaultSecondaryTextColor = Color(0xFF4B5563);
  static const Color defaultMutedTextColor = Color(0xFF6B7280);
  static const Color defaultPlaceholderColor = Color(0xFF9CA3AF);
  static const Color defaultErrorColor = Color(0xFFDC2626);
  static const Color defaultErrorBackgroundColor = Color(0xFFFEE2E2);
  static const Color defaultSuccessColor = Color(0xFF16A34A);
  static const Color defaultSuccessBackgroundColor = Color(0xFFDCFCE7);
  static const Color defaultWarningColor = Color(0xFFD97706);
  static const Color defaultWarningBackgroundColor = Color(0xFFFEF3C7);
  static const Color defaultInfoColor = Color(0xFF1D4ED8);
  static const Color defaultInfoBackgroundColor = Color(0xFFDBEAFE);
  static const Color defaultButtonColor = Color(0xFF2563EB);
  static const Color defaultDisabledButtonColor = Color(0xFF93C5FD);

  /// Primary accent/brand color.
  final Color primaryColor;

  /// Light tint of primary color used for subtle highlights and chips.
  final Color primaryLightColor;

  /// Dark shade of primary color used for high-contrast accents.
  final Color primaryDarkColor;

  /// Border color for light primary containers.
  final Color primaryLightBorderColor;

  /// Foreground content color when placed on [primaryColor].
  final Color onPrimaryColor;

  /// Main screen/scaffold background color.
  final Color backgroundColor;

  /// Card, dialog, sheet, and surface container background color.
  final Color surfaceColor;

  /// Secondary/subtle background for chips, inputs, and segment selectors.
  final Color secondaryBackgroundColor;

  /// Standard border color for cards, dividers, and outlines.
  final Color borderColor;

  /// Muted border color for inactive controls or secondary borders.
  final Color borderMutedColor;

  /// High-contrast heading and title text color.
  final Color titleColor;

  /// Primary body and readable text color.
  final Color textColor;

  /// Secondary body text color.
  final Color secondaryTextColor;

  /// Muted text, captions, and secondary icon color.
  final Color mutedTextColor;

  /// Placeholder, hint text, and empty-state icon color.
  final Color placeholderColor;

  /// Destructive/error and bug indicator color.
  final Color errorColor;

  /// Light tint background for error banners and bug badges.
  final Color errorBackgroundColor;

  /// Success and shipped status color.
  final Color successColor;

  /// Light tint background for success states and shipped badges.
  final Color successBackgroundColor;

  /// Warning, pending, and planned status color.
  final Color warningColor;

  /// Light tint background for warning states and planned badges.
  final Color warningBackgroundColor;

  /// Informational and in-progress status color.
  final Color infoColor;

  /// Light tint background for in-progress badges.
  final Color infoBackgroundColor;

  /// Primary action button background color.
  final Color buttonColor;

  /// Disabled state background color for buttons.
  final Color disabledButtonColor;

  const FeedbackOSTheme({
    Color? primaryColor,
    Color? primaryLightColor,
    Color? primaryDarkColor,
    Color? primaryLightBorderColor,
    Color? onPrimaryColor,
    Color? backgroundColor,
    Color? surfaceColor,
    Color? secondaryBackgroundColor,
    Color? borderColor,
    Color? borderMutedColor,
    Color? titleColor,
    Color? textColor,
    Color? secondaryTextColor,
    Color? mutedTextColor,
    Color? placeholderColor,
    Color? errorColor,
    Color? errorBackgroundColor,
    Color? successColor,
    Color? successBackgroundColor,
    Color? warningColor,
    Color? warningBackgroundColor,
    Color? infoColor,
    Color? infoBackgroundColor,
    Color? buttonColor,
    Color? disabledButtonColor,
  })  : primaryColor = primaryColor ?? defaultPrimaryColor,
        primaryLightColor = primaryLightColor ?? defaultPrimaryLightColor,
        primaryDarkColor = primaryDarkColor ?? defaultPrimaryDarkColor,
        primaryLightBorderColor =
            primaryLightBorderColor ?? defaultPrimaryLightBorderColor,
        onPrimaryColor = onPrimaryColor ?? defaultOnPrimaryColor,
        backgroundColor = backgroundColor ?? defaultBackgroundColor,
        surfaceColor = surfaceColor ?? defaultSurfaceColor,
        secondaryBackgroundColor =
            secondaryBackgroundColor ?? defaultSecondaryBackgroundColor,
        borderColor = borderColor ?? defaultBorderColor,
        borderMutedColor = borderMutedColor ?? defaultBorderMutedColor,
        titleColor = titleColor ?? defaultTitleColor,
        textColor = textColor ?? defaultTextColor,
        secondaryTextColor = secondaryTextColor ?? defaultSecondaryTextColor,
        mutedTextColor = mutedTextColor ?? defaultMutedTextColor,
        placeholderColor = placeholderColor ?? defaultPlaceholderColor,
        errorColor = errorColor ?? defaultErrorColor,
        errorBackgroundColor =
            errorBackgroundColor ?? defaultErrorBackgroundColor,
        successColor = successColor ?? defaultSuccessColor,
        successBackgroundColor =
            successBackgroundColor ?? defaultSuccessBackgroundColor,
        warningColor = warningColor ?? defaultWarningColor,
        warningBackgroundColor =
            warningBackgroundColor ?? defaultWarningBackgroundColor,
        infoColor = infoColor ?? defaultInfoColor,
        infoBackgroundColor = infoBackgroundColor ?? defaultInfoBackgroundColor,
        buttonColor = buttonColor ?? primaryColor ?? defaultButtonColor,
        disabledButtonColor = disabledButtonColor ?? defaultDisabledButtonColor;

  /// Predefined light theme matching default styling.
  factory FeedbackOSTheme.light() => const FeedbackOSTheme();

  /// Predefined dark theme for dark mode applications.
  factory FeedbackOSTheme.dark() {
    return const FeedbackOSTheme(
      primaryColor: Color(0xFF6366F1),
      primaryLightColor: Color(0xFF312E81),
      primaryDarkColor: Color(0xFFC7D2FE),
      primaryLightBorderColor: Color(0xFF4338CA),
      onPrimaryColor: Colors.white,
      backgroundColor: Color(0xFF111827),
      surfaceColor: Color(0xFF1F2937),
      secondaryBackgroundColor: Color(0xFF374151),
      borderColor: Color(0xFF374151),
      borderMutedColor: Color(0xFF4B5563),
      titleColor: Color(0xFFF9FAFB),
      textColor: Color(0xFFE5E7EB),
      secondaryTextColor: Color(0xFFD1D5DB),
      mutedTextColor: Color(0xFF9CA3AF),
      placeholderColor: Color(0xFF6B7280),
      errorColor: Color(0xFFEF4444),
      errorBackgroundColor: Color(0xFF450A0A),
      successColor: Color(0xFF22C55E),
      successBackgroundColor: Color(0xFF052E16),
      warningColor: Color(0xFFF59E0B),
      warningBackgroundColor: Color(0xFF451A03),
      infoColor: Color(0xFF3B82F6),
      infoBackgroundColor: Color(0xFF1E3A8A),
      buttonColor: Color(0xFF4F46E5),
      disabledButtonColor: Color(0xFF3730A3),
    );
  }

  /// Derives theme colors from Flutter's standard [ThemeData].
  factory FeedbackOSTheme.fromTheme(ThemeData theme) {
    final cs = theme.colorScheme;
    return FeedbackOSTheme(
      primaryColor: cs.primary,
      onPrimaryColor: cs.onPrimary,
      backgroundColor: cs.surface,
      surfaceColor: cs.surfaceContainerLowest,
      secondaryBackgroundColor: cs.surfaceContainerHighest,
      borderColor: cs.outlineVariant,
      titleColor: cs.onSurface,
      textColor: cs.onSurface,
      secondaryTextColor: cs.onSurfaceVariant,
      mutedTextColor: cs.onSurfaceVariant.withAlpha(180),
      errorColor: cs.error,
      buttonColor: cs.primary,
    );
  }

  /// Whether this theme represents a dark theme based on [backgroundColor] luminance.
  bool get isDark => backgroundColor.computeLuminance() < 0.5;

  /// Global runtime theme instance, set during SDK initialization.
  static FeedbackOSTheme? _current;

  /// Returns the current runtime theme, or the default fallback if unset.
  static FeedbackOSTheme get current => _current ?? const FeedbackOSTheme();

  /// Updates the global runtime theme.
  static set current(FeedbackOSTheme? theme) => _current = theme;

  /// Resolves the effective [FeedbackOSTheme] from the [BuildContext].
  ///
  /// Checks for an enclosing [FeedbackOSThemeProvider] first, then falls back
  /// to the global runtime theme [FeedbackOSTheme.current].
  static FeedbackOSTheme of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<FeedbackOSThemeProvider>();
    if (provider != null) {
      return provider.theme;
    }
    return current;
  }

  /// Resolves the background color for a roadmap/item status badge.
  Color statusBackgroundColor(String status) {
    return switch (status.toLowerCase()) {
      'planned' => warningBackgroundColor,
      'in_progress' => infoBackgroundColor,
      'shipped' => successBackgroundColor,
      _ => secondaryBackgroundColor,
    };
  }

  /// Resolves the foreground/text color for a roadmap/item status badge.
  Color statusForegroundColor(String status) {
    return switch (status.toLowerCase()) {
      'planned' => warningColor,
      'in_progress' => infoColor,
      'shipped' => successColor,
      _ => secondaryTextColor,
    };
  }

  /// Creates a copy of this theme with the given fields replaced.
  FeedbackOSTheme copyWith({
    Color? primaryColor,
    Color? primaryLightColor,
    Color? primaryDarkColor,
    Color? primaryLightBorderColor,
    Color? onPrimaryColor,
    Color? backgroundColor,
    Color? surfaceColor,
    Color? secondaryBackgroundColor,
    Color? borderColor,
    Color? borderMutedColor,
    Color? titleColor,
    Color? textColor,
    Color? secondaryTextColor,
    Color? mutedTextColor,
    Color? placeholderColor,
    Color? errorColor,
    Color? errorBackgroundColor,
    Color? successColor,
    Color? successBackgroundColor,
    Color? warningColor,
    Color? warningBackgroundColor,
    Color? infoColor,
    Color? infoBackgroundColor,
    Color? buttonColor,
    Color? disabledButtonColor,
  }) {
    return FeedbackOSTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      primaryLightColor: primaryLightColor ?? this.primaryLightColor,
      primaryDarkColor: primaryDarkColor ?? this.primaryDarkColor,
      primaryLightBorderColor:
          primaryLightBorderColor ?? this.primaryLightBorderColor,
      onPrimaryColor: onPrimaryColor ?? this.onPrimaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      secondaryBackgroundColor:
          secondaryBackgroundColor ?? this.secondaryBackgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderMutedColor: borderMutedColor ?? this.borderMutedColor,
      titleColor: titleColor ?? this.titleColor,
      textColor: textColor ?? this.textColor,
      secondaryTextColor: secondaryTextColor ?? this.secondaryTextColor,
      mutedTextColor: mutedTextColor ?? this.mutedTextColor,
      placeholderColor: placeholderColor ?? this.placeholderColor,
      errorColor: errorColor ?? this.errorColor,
      errorBackgroundColor: errorBackgroundColor ?? this.errorBackgroundColor,
      successColor: successColor ?? this.successColor,
      successBackgroundColor:
          successBackgroundColor ?? this.successBackgroundColor,
      warningColor: warningColor ?? this.warningColor,
      warningBackgroundColor:
          warningBackgroundColor ?? this.warningBackgroundColor,
      infoColor: infoColor ?? this.infoColor,
      infoBackgroundColor: infoBackgroundColor ?? this.infoBackgroundColor,
      buttonColor: buttonColor ?? this.buttonColor,
      disabledButtonColor: disabledButtonColor ?? this.disabledButtonColor,
    );
  }

  @override
  List<Object?> get props => [
        primaryColor,
        primaryLightColor,
        primaryDarkColor,
        primaryLightBorderColor,
        onPrimaryColor,
        backgroundColor,
        surfaceColor,
        secondaryBackgroundColor,
        borderColor,
        borderMutedColor,
        titleColor,
        textColor,
        secondaryTextColor,
        mutedTextColor,
        placeholderColor,
        errorColor,
        errorBackgroundColor,
        successColor,
        successBackgroundColor,
        warningColor,
        warningBackgroundColor,
        infoColor,
        infoBackgroundColor,
        buttonColor,
        disabledButtonColor,
      ];
}

/// An [InheritedWidget] providing [FeedbackOSTheme] down the widget tree.
class FeedbackOSThemeProvider extends InheritedWidget {
  final FeedbackOSTheme theme;

  const FeedbackOSThemeProvider({
    super.key,
    required this.theme,
    required super.child,
  });

  @override
  bool updateShouldNotify(FeedbackOSThemeProvider oldWidget) =>
      theme != oldWidget.theme;
}
