import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Paleta oficial Rosé Pine y Rosé Pine Dawn
/// Inspirada en la estética minimalista y serena de FinanzApp.
class RosePineDark {
  static const Color base = Color(0xFF191724);
  static const Color surface = Color(0xFF1F1D2E);
  static const Color overlay = Color(0xFF26233A);
  static const Color muted = Color(0xFF6E6A86);
  static const Color subtle = Color(0xFF908CAA);
  static const Color text = Color(0xFFE0DEF4);
  static const Color love = Color(0xFFEB6F92); // Red / Accent
  static const Color gold = Color(0xFFF6C177); // Yellow / Warning
  static const Color rose = Color(0xFFEBBCBA);
  static const Color pine = Color(0xFF31748F); // Pine / Blue brand
  static const Color foam = Color(0xFF9CCFD8); // Teal
  static const Color iris = Color(0xFFC4A7E7); // Purple
  static const Color success = Color(0xFF2D957B); // Success / Confirmo (FinanzApp)
  static const Color border = Color(0x14FFFFFF); // 8% white
  static const Color borderHover = Color(0x24FFFFFF);
}

class RosePineDawn {
  static const Color base = Color(0xFFF4F1EA); // Soft warm canvas with high contrast against white cards
  static const Color surface = Color(0xFFFFFFFF); // Pure crisp white for cards, docks, and modals
  static const Color overlay = Color(0xFFE8E3DB); // Clear, distinct chip and input background
  static const Color muted = Color(0xFF6B667D); // Deep readable slate gray
  static const Color subtle = Color(0xFF433F5A); // Strong, legible slate for unselected tabs & subtitles
  static const Color text = Color(0xFF1F1D2E); // Deep ink / charcoal for maximum readability
  static const Color love = Color(0xFFD9446C); // Vibrant raspberry rose
  static const Color gold = Color(0xFFD97706); // Rich amber
  static const Color rose = Color(0xFFC45A55);
  static const Color pine = Color(0xFF1E5B73); // Deep pine blue brand
  static const Color foam = Color(0xFF2B7886); // Teal
  static const Color iris = Color(0xFF7C3AED); // Purple
  static const Color success = Color(0xFF168058); // Forest green
  static const Color border = Color(0xFFDCD6CC); // Clearly defined border for cards
  static const Color borderHover = Color(0xFFC5BDAF);
}

class AppTheme {
  // Notificador global para alternar entre Modo Claro, Modo Oscuro o Sistema
  // Por defecto iniciamos en Modo Oscuro (Rosé Pine) para igualar la experiencia de FinanzApp
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

  static const _storage = FlutterSecureStorage();
  static const String _storageKey = 'app_theme_mode';

  /// Carga la preferencia guardada de tema
  static Future<void> loadSavedTheme() async {
    try {
      final saved = await _storage.read(key: _storageKey);
      if (saved == 'light') {
        themeNotifier.value = ThemeMode.light;
      } else if (saved == 'dark') {
        themeNotifier.value = ThemeMode.dark;
      } else if (saved == 'system') {
        themeNotifier.value = ThemeMode.system;
      } else {
        themeNotifier.value = ThemeMode.dark;
      }
    } catch (_) {
      themeNotifier.value = ThemeMode.dark;
    }
  }

  /// Alterna instantáneamente entre Modo Oscuro y Modo Claro
  static Future<void> toggleTheme() async {
    final current = themeNotifier.value;
    final next = current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    themeNotifier.value = next;
    try {
      await _storage.write(key: _storageKey, value: next.name);
    } catch (_) {}
  }

  /// Establece un modo específico (light, dark, system)
  static Future<void> setTheme(ThemeMode mode) async {
    themeNotifier.value = mode;
    try {
      await _storage.write(key: _storageKey, value: mode.name);
    } catch (_) {}
  }

  // Mapeo retrocompatible con la paleta Rosé Pine
  static const Color primaryBlue = Color(0xFF31748F); // Pine
  static const Color primaryBlueLight = Color(0xFF56949F); // Foam
  static const Color accentRed = Color(0xFFEB6F92); // Love
  static const Color backgroundLight = Color(0xFFF4F1EA); // Dawn base
  static const Color cardColor = Color(0xFFFFFFFF); // Dawn surface
  static const Color textPrimary = Color(0xFF1F1D2E); // Dawn text
  static const Color textSecondary = Color(0xFF433F5A); // Dawn subtle
  static const Color borderSubtle = Color(0xFFDCD6CC); // Dawn border
  static const Color confirmationGreen = Color(0xFF168058); // Success

  // --- TEMA CLARO (Rosé Pine Dawn - Alto Contraste) ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: RosePineDawn.base,
      colorScheme: const ColorScheme.light(
        primary: RosePineDawn.love,
        secondary: RosePineDawn.pine,
        tertiary: RosePineDawn.foam,
        surface: RosePineDawn.surface,
        error: RosePineDawn.love,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: RosePineDawn.text,
        outline: RosePineDawn.border,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: RosePineDawn.surface,
        foregroundColor: RosePineDawn.text,
        elevation: 0.5,
        scrolledUnderElevation: 1.0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: RosePineDawn.text,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: RosePineDawn.text),
      ),
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: RosePineDawn.surface,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: RosePineDawn.surface,
        selectedItemColor: RosePineDawn.love,
        unselectedItemColor: RosePineDawn.muted,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RosePineDawn.love,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: RosePineDawn.pine,
          side: const BorderSide(color: RosePineDawn.border, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
        ),
      ),
      cardTheme: CardThemeData(
        color: RosePineDawn.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: RosePineDawn.border, width: 1.2),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: RosePineDawn.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: RosePineDawn.border, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: RosePineDawn.border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: RosePineDawn.love, width: 1.5),
        ),
        labelStyle: const TextStyle(color: RosePineDawn.subtle, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: RosePineDawn.muted),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: RosePineDawn.love,
        unselectedLabelColor: RosePineDawn.subtle,
        indicatorColor: RosePineDawn.love,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: RosePineDawn.surface,
        modalBackgroundColor: RosePineDawn.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: RosePineDawn.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: RosePineDawn.border, width: 1.2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: RosePineDawn.overlay,
        selectedColor: RosePineDawn.love.withValues(alpha: 0.15),
        side: const BorderSide(color: RosePineDawn.border, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: const TextStyle(fontSize: 12, color: RosePineDawn.text, fontWeight: FontWeight.w600),
      ),
      dividerColor: RosePineDawn.border,
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: RosePineDawn.text, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: RosePineDawn.text, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(color: RosePineDawn.text),
        bodyMedium: TextStyle(color: RosePineDawn.subtle),
      ),
    );
  }

  // --- TEMA OSCURO (Rosé Pine Main / Moon) ---
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: RosePineDark.base,
      colorScheme: const ColorScheme.dark(
        primary: RosePineDark.love,
        secondary: RosePineDark.pine,
        tertiary: RosePineDark.foam,
        surface: RosePineDark.surface,
        error: RosePineDark.love,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: RosePineDark.text,
        outline: RosePineDark.border,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: RosePineDark.surface,
        foregroundColor: RosePineDark.text,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: RosePineDark.text,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: RosePineDark.text),
      ),
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: RosePineDark.surface,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: RosePineDark.surface,
        selectedItemColor: RosePineDark.love,
        unselectedItemColor: RosePineDark.muted,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RosePineDark.love,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: RosePineDark.foam,
          side: const BorderSide(color: RosePineDark.border, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
        ),
      ),
      cardTheme: CardThemeData(
        color: RosePineDark.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: RosePineDark.border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: RosePineDark.overlay,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: RosePineDark.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: RosePineDark.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: RosePineDark.love, width: 1.5),
        ),
        labelStyle: const TextStyle(color: RosePineDark.subtle),
        hintStyle: const TextStyle(color: RosePineDark.muted),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: RosePineDark.love,
        unselectedLabelColor: RosePineDark.muted,
        indicatorColor: RosePineDark.love,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: RosePineDark.surface,
        modalBackgroundColor: RosePineDark.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: RosePineDark.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: RosePineDark.border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: RosePineDark.overlay,
        selectedColor: RosePineDark.love.withValues(alpha: 0.2),
        side: const BorderSide(color: RosePineDark.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: const TextStyle(fontSize: 12, color: RosePineDark.text),
      ),
      dividerColor: RosePineDark.border,
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: RosePineDark.text, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: RosePineDark.text, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: RosePineDark.text),
        bodyMedium: TextStyle(color: RosePineDark.subtle),
      ),
    );
  }
}

extension ThemeHelper on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  Color get baseColor => isDarkMode ? RosePineDark.base : RosePineDawn.base;
  Color get surfaceColor => isDarkMode ? RosePineDark.surface : RosePineDawn.surface;
  Color get overlayColor => isDarkMode ? RosePineDark.overlay : RosePineDawn.overlay;
  Color get subtleColor => isDarkMode ? RosePineDark.subtle : RosePineDawn.subtle;
  Color get mutedColor => isDarkMode ? RosePineDark.muted : RosePineDawn.muted;
  Color get borderColor => isDarkMode ? RosePineDark.border : RosePineDawn.border;
  Color get textPrimaryColor => isDarkMode ? RosePineDark.text : RosePineDawn.text;
  Color get loveColor => isDarkMode ? RosePineDark.love : RosePineDawn.love;
  Color get pineColor => isDarkMode ? RosePineDark.pine : RosePineDawn.pine;
  Color get foamColor => isDarkMode ? RosePineDark.foam : RosePineDawn.foam;
  Color get irisColor => isDarkMode ? RosePineDark.iris : RosePineDawn.iris;
  Color get goldColor => isDarkMode ? RosePineDark.gold : RosePineDawn.gold;
  Color get successColor => isDarkMode ? RosePineDark.success : RosePineDawn.success;
}
