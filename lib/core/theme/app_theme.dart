import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/settings.dart';

/// Accent palette definition (light + dark variants).
class _Accent {
  const _Accent(this.light, this.lightContainer, this.dark, this.darkContainer);
  final Color light;
  final Color lightContainer;
  final Color dark;
  final Color darkContainer;
}

const Map<AccentPalette, _Accent> _accents = {
  AccentPalette.indigo: _Accent(Color(0xFF5B4BDB), Color(0xFFE9E5FF), Color(0xFFB0A5FF), Color(0xFF3B3480)),
  AccentPalette.teal: _Accent(Color(0xFF0E8F8A), Color(0xFFD5F3F0), Color(0xFF6FD6CF), Color(0xFF0F4B48)),
  AccentPalette.rose: _Accent(Color(0xFFD1447A), Color(0xFFFFE1EC), Color(0xFFFF9BBF), Color(0xFF6E2144)),
  AccentPalette.amber: _Accent(Color(0xFFB26A00), Color(0xFFFFEBC8), Color(0xFFFFC463), Color(0xFF5C3900)),
  AccentPalette.slate: _Accent(Color(0xFF475569), Color(0xFFE3E8EF), Color(0xFFB4C0D0), Color(0xFF2E3846)),
};

Color accentColor(AccentPalette a, Brightness b) =>
    b == Brightness.light ? _accents[a]!.light : _accents[a]!.dark;

/// Semantic colours that are not part of [ColorScheme].
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.warning,
    required this.danger,
    required this.lavender,
    required this.cardBorder,
    required this.subtle,
  });

  final Color success;
  final Color warning;
  final Color danger;
  final Color lavender;
  final Color cardBorder;
  final Color subtle;

  @override
  AppColors copyWith({Color? success, Color? warning, Color? danger, Color? lavender, Color? cardBorder, Color? subtle}) =>
      AppColors(
        success: success ?? this.success,
        warning: warning ?? this.warning,
        danger: danger ?? this.danger,
        lavender: lavender ?? this.lavender,
        cardBorder: cardBorder ?? this.cardBorder,
        subtle: subtle ?? this.subtle,
      );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      lavender: Color.lerp(lavender, other.lavender, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      subtle: Color.lerp(subtle, other.subtle, t)!,
    );
  }
}

class AppTheme {
  const AppTheme._();

  static const String fontFamily = 'Vazirmatn';

  static ThemeData build(Brightness brightness, AccentPalette accent) {
    final a = _accents[accent]!;
    final light = brightness == Brightness.light;
    final primary = light ? a.light : a.dark;
    final container = light ? a.lightContainer : a.darkContainer;

    final scheme = light
        ? ColorScheme.light(
            primary: primary,
            onPrimary: Colors.white,
            primaryContainer: container,
            onPrimaryContainer: const Color(0xFF1E1550),
            secondary: const Color(0xFF8B7BFF),
            secondaryContainer: const Color(0xFFEFEBFF),
            onSecondaryContainer: const Color(0xFF2A2170),
            surface: Colors.white,
            onSurface: const Color(0xFF1B1A24),
            onSurfaceVariant: const Color(0xFF6A6779),
            surfaceContainerLowest: Colors.white,
            surfaceContainerLow: const Color(0xFFFAF9FE),
            surfaceContainer: const Color(0xFFF3F1FA),
            surfaceContainerHigh: const Color(0xFFEDEAF6),
            surfaceContainerHighest: const Color(0xFFE6E3F1),
            outline: const Color(0xFFB9B5CA),
            outlineVariant: const Color(0xFFE3E0EF),
            error: const Color(0xFFC62F3E),
            onError: Colors.white,
          )
        : ColorScheme.dark(
            primary: primary,
            onPrimary: const Color(0xFF1B1550),
            primaryContainer: container,
            onPrimaryContainer: const Color(0xFFEAE6FF),
            secondary: const Color(0xFF9D90FF),
            secondaryContainer: const Color(0xFF2E2A52),
            onSecondaryContainer: const Color(0xFFE4E0FF),
            surface: const Color(0xFF1B1A25),
            onSurface: const Color(0xFFECEAF6),
            onSurfaceVariant: const Color(0xFFA9A6BB),
            surfaceContainerLowest: const Color(0xFF12111A),
            surfaceContainerLow: const Color(0xFF191822),
            surfaceContainer: const Color(0xFF212030),
            surfaceContainerHigh: const Color(0xFF292838),
            surfaceContainerHighest: const Color(0xFF322F44),
            outline: const Color(0xFF5B5872),
            outlineVariant: const Color(0xFF2E2C40),
            error: const Color(0xFFFF8A94),
            onError: const Color(0xFF3B0810),
          );

    final scaffold = light ? const Color(0xFFF6F5FB) : const Color(0xFF14131C);

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: scaffold,
      visualDensity: VisualDensity.standard,
    );

    final text = base.textTheme.apply(
      fontFamily: fontFamily,
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    TextStyle t(TextStyle? s, double size, FontWeight w, {double h = 1.5}) =>
        (s ?? const TextStyle()).copyWith(fontSize: size, fontWeight: w, height: h, fontFamily: fontFamily);

    final textTheme = text.copyWith(
      displayLarge: t(text.displayLarge, 44, FontWeight.w700, h: 1.2),
      displayMedium: t(text.displayMedium, 36, FontWeight.w700, h: 1.25),
      headlineLarge: t(text.headlineLarge, 30, FontWeight.w700, h: 1.3),
      headlineMedium: t(text.headlineMedium, 26, FontWeight.w700, h: 1.35),
      headlineSmall: t(text.headlineSmall, 22, FontWeight.w700, h: 1.4),
      titleLarge: t(text.titleLarge, 20, FontWeight.w700),
      titleMedium: t(text.titleMedium, 16, FontWeight.w600),
      titleSmall: t(text.titleSmall, 14, FontWeight.w600),
      bodyLarge: t(text.bodyLarge, 16, FontWeight.w400, h: 1.6),
      bodyMedium: t(text.bodyMedium, 14.5, FontWeight.w400, h: 1.6),
      bodySmall: t(text.bodySmall, 12.5, FontWeight.w400, h: 1.5),
      labelLarge: t(text.labelLarge, 14.5, FontWeight.w600),
      labelMedium: t(text.labelMedium, 12.5, FontWeight.w500),
      labelSmall: t(text.labelSmall, 11.5, FontWeight.w500),
    );

    final radius = BorderRadius.circular(16);
    return base.copyWith(
      textTheme: textTheme,
      extensions: [
        AppColors(
          success: light ? const Color(0xFF1E9E63) : const Color(0xFF5BD69B),
          warning: light ? const Color(0xFFC77A00) : const Color(0xFFFFC463),
          danger: scheme.error,
          lavender: light ? const Color(0xFFEFEBFF) : const Color(0xFF2B2750),
          cardBorder: scheme.outlineVariant,
          subtle: scheme.onSurfaceVariant,
        ),
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        foregroundColor: scheme.onSurface,
        systemOverlayStyle: light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: radius),
          side: BorderSide(color: scheme.outline),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainer,
        selectedColor: scheme.primaryContainer,
        side: BorderSide.none,
        labelStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: scheme.outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: light ? const Color(0xFF2A2838) : const Color(0xFFECEAF6),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: light ? Colors.white : const Color(0xFF1B1A24),
        ),
        actionTextColor: light ? const Color(0xFFCFC8FF) : const Color(0xFF4B3FC0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1, thickness: 1),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        minVerticalPadding: 10,
        titleTextStyle: textTheme.titleSmall?.copyWith(color: scheme.onSurface),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? scheme.onPrimary : scheme.outline),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? scheme.primary : scheme.surfaceContainerHighest),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
      }),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
  ColorScheme get scheme => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}
