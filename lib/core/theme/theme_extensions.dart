import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Extra semantic colors that adapt to light/dark mode.
@immutable
class AppThemeExtras extends ThemeExtension<AppThemeExtras> {
  final Color cardBackground;
  final Color tableHeaderBackground;
  final Color secondaryText;
  final Color hintText;
  final Color bottomBarBackground;
  final Color drawerBackground;
  final List<BoxShadow> cardShadow;

  const AppThemeExtras({
    required this.cardBackground,
    required this.tableHeaderBackground,
    required this.secondaryText,
    required this.hintText,
    required this.bottomBarBackground,
    required this.drawerBackground,
    required this.cardShadow,
  });

  static final light = AppThemeExtras(
    cardBackground: AppTheme.white,
    tableHeaderBackground: AppTheme.lightBackground,
    secondaryText: AppTheme.textSecondary,
    hintText: AppTheme.textHint,
    bottomBarBackground: AppTheme.white,
    drawerBackground: AppTheme.primaryTeal,
    cardShadow: AppTheme.cardShadow,
  );

  static final dark = AppThemeExtras(
    cardBackground: AppTheme.darkSurface,
    tableHeaderBackground: const Color(0xFF2A2A2A),
    secondaryText: AppTheme.darkTextSecondary,
    hintText: const Color(0xFF808080),
    bottomBarBackground: AppTheme.darkSurface,
    drawerBackground: AppTheme.darkTeal,
    cardShadow: const [
      BoxShadow(
        color: Color(0x40000000),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  );

  @override
  AppThemeExtras copyWith({
    Color? cardBackground,
    Color? tableHeaderBackground,
    Color? secondaryText,
    Color? hintText,
    Color? bottomBarBackground,
    Color? drawerBackground,
    List<BoxShadow>? cardShadow,
  }) {
    return AppThemeExtras(
      cardBackground: cardBackground ?? this.cardBackground,
      tableHeaderBackground:
          tableHeaderBackground ?? this.tableHeaderBackground,
      secondaryText: secondaryText ?? this.secondaryText,
      hintText: hintText ?? this.hintText,
      bottomBarBackground: bottomBarBackground ?? this.bottomBarBackground,
      drawerBackground: drawerBackground ?? this.drawerBackground,
      cardShadow: cardShadow ?? this.cardShadow,
    );
  }

  @override
  AppThemeExtras lerp(ThemeExtension<AppThemeExtras>? other, double t) {
    if (other is! AppThemeExtras) return this;
    return AppThemeExtras(
      cardBackground:
          Color.lerp(cardBackground, other.cardBackground, t)!,
      tableHeaderBackground: Color.lerp(
          tableHeaderBackground, other.tableHeaderBackground, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      hintText: Color.lerp(hintText, other.hintText, t)!,
      bottomBarBackground:
          Color.lerp(bottomBarBackground, other.bottomBarBackground, t)!,
      drawerBackground:
          Color.lerp(drawerBackground, other.drawerBackground, t)!,
      cardShadow: t < 0.5 ? cardShadow : other.cardShadow,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppThemeExtras get appExtras =>
      Theme.of(this).extension<AppThemeExtras>() ?? AppThemeExtras.light;

  Color get cardColor => appExtras.cardBackground;
  Color get secondaryTextColor => appExtras.secondaryText;
}
