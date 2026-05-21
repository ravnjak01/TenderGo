import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────
//  AppColors  –  single source of truth for every colour in the app
// ─────────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────
  static const primary     = Color(0xFF2563EB);
  static const primaryDark = Color(0xFF1E40AF);
  static const primaryLight = Color(0xFF3B82F6); // hover / splash tint
  static const secondary   = Color(0xFF185FA5); // tender-specific accent

  // ── Backgrounds ────────────────────────────────────────────────
  static const background  = Color(0xFFF9FAFB); // scaffold
  static const surface     = Color(0xFFFFFFFF); // cards, sheets
  static const surfaceVariant = Color(0xFFF3F4F6); // input fills, alt cards

  /// Used ONLY on the login / register screen as a local override.
  /// Apply via `Scaffold(backgroundColor: AppColors.authBackground)`.
  static const authBackground = Color(0xFF254988);

  // ── Text ───────────────────────────────────────────────────────
  static const textPrimary   = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textDisabled  = Color(0xFFD1D5DB);

  // ── Border / Outline ───────────────────────────────────────────
  static const outline      = Color(0xFFE5E7EB);
  static const outlineFocus = primary;

  // ── Semantic ───────────────────────────────────────────────────
  static const success        = Color(0xFF16A34A);
  static const successSurface = Color(0xFFDCFCE7);
  static const error          = Color(0xFFDC2626);
  static const errorSurface   = Color(0xFFFEE2E2);
  static const warning        = Color(0xFFF59E0B);
  static const warningSurface = Color(0xFFFEF3C7);
  static const info           = Color(0xFF0EA5E9);
  static const infoSurface    = Color(0xFFE0F2FE);
}

// ─────────────────────────────────────────────────────────────────
//  AppTheme
// ─────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,

      // ── Primary ────────────────────────────────────────────────
      primary:          AppColors.primary,
      onPrimary:        Colors.white,
      primaryContainer: Color(0xFFDBEAFE), // light blue tint
      onPrimaryContainer: AppColors.primaryDark,

      // ── Secondary (brand dark, used for FABs, toggles) ─────────
      secondary:          AppColors.primaryDark,
      onSecondary:        Colors.white,
      secondaryContainer: Color(0xFFBFDBFE),
      onSecondaryContainer: AppColors.primaryDark,

      // ── Tertiary (accent – use for chips, badges) ──────────────
      tertiary:          AppColors.info,
      onTertiary:        Colors.white,
      tertiaryContainer: AppColors.infoSurface,
      onTertiaryContainer: Color(0xFF0C4A6E),

      // ── Error ──────────────────────────────────────────────────
      error:          AppColors.error,
      onError:        Colors.white,
      errorContainer: AppColors.errorSurface,
      onErrorContainer: Color(0xFF7F1D1D),

      // ── Surfaces (M3 replaces background/onBackground) ─────────
      surface:                AppColors.surface,
      onSurface:              AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceVariant,
      onSurfaceVariant:       AppColors.textSecondary,

      // ── Misc ───────────────────────────────────────────────────
      outline:        AppColors.outline,
      outlineVariant: Color(0xFFF3F4F6),
      shadow:         Color(0x1A111827),
      scrim:          Color(0x66111827),
      inverseSurface:   AppColors.textPrimary,
      onInverseSurface: AppColors.background,
      inversePrimary:   AppColors.primaryLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      // ── Scaffold ───────────────────────────────────────────────
      scaffoldBackgroundColor: AppColors.background,

      // ── System UI overlay ──────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Color(0x1A111827),
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary, size: 22),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),

      // ── Typography ─────────────────────────────────────────────
      textTheme: const TextTheme(
        // Display
        displayLarge:  TextStyle(fontSize: 57, fontWeight: FontWeight.w400, color: AppColors.textPrimary, letterSpacing: -0.25),
        displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        displaySmall:  TextStyle(fontSize: 36, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        // Headline
        headlineLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        headlineSmall:  TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        // Title  ← most commonly used in AppBars, dialogs, cards
        titleLarge:  TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        titleSmall:  TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        // Body
        bodyLarge:   TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        bodyMedium:  TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
        bodySmall:   TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
        // Label  ← buttons, chips, tabs
        labelLarge:  TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
        labelSmall:  TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textSecondary, letterSpacing: 0.5),
      ),

      // ── Icon ───────────────────────────────────────────────────
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 22,
      ),

      // ── Buttons ────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.textDisabled,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          minimumSize: const Size(0, 48),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.textDisabled,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          minimumSize: const Size(0, 48),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.textDisabled,
          textStyle: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(0, 40),
        ),
      ),

      // ── Inputs ─────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        // Label
        labelStyle: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary),
        floatingLabelStyle: const TextStyle(
            fontSize: 13,
            color: AppColors.primary,
            fontWeight: FontWeight.w500),
        // Hint
        hintStyle: const TextStyle(
            fontSize: 14,
            color: AppColors.textDisabled),
        // Borders
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.error, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.textDisabled),
        ),
        // Error text
        errorStyle: const TextStyle(
            fontSize: 12, color: AppColors.error),
        // Sizing
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        isDense: false,
      ),

      // ── Card ───────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.outline),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Divider ────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.outline,
        thickness: 1,
        space: 1,
      ),

      // ── Chip ───────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primary.withOpacity(0.15),
        labelStyle: const TextStyle(
            fontSize: 13,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500),
        side: const BorderSide(color: AppColors.outline),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      // ── Dialog ─────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
        contentTextStyle: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary),
      ),

      // ── BottomSheet ────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20)),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.outline,
      ),

      // ── SnackBar ───────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(
            color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),

      // ── ListTile ───────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        contentPadding:
            EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary),
        subtitleTextStyle: TextStyle(
            fontSize: 13, color: AppColors.textSecondary),
        iconColor: AppColors.textSecondary,
        minLeadingWidth: 20,
      ),

      // ── Switch / Checkbox / Radio ──────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return AppColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.outline;
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: AppColors.outline, width: 1.5),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4)),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.textSecondary;
        }),
      ),

      // ── Progress indicators ────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceVariant,
        circularTrackColor: AppColors.surfaceVariant,
      ),

      // ── Tab bar ────────────────────────────────────────────────
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle:
            TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        dividerColor: AppColors.outline,
      ),

      // ── FloatingActionButton ───────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: CircleBorder(),
      ),
    );
  }
}