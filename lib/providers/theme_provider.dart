import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true; // Default to dark as requested

  bool get isDarkMode => _isDarkMode;

  ThemeData get themeData => _isDarkMode ? darkTheme : lightTheme;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF1D9E75),
    scaffoldBackgroundColor: const Color(0xFF0D0D15),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF1D9E75),
      secondary: Color(0xFF00D2FD),
      surface: Color(0xFF131318),
      onSurface: Colors.white,
      onSurfaceVariant: Colors.white60,
      outline: Color(0xFF1E2830),
    ),
    cardColor: const Color(0xFF1F1F25),
    cardTheme: CardThemeData(
      color: const Color(0xFF1F1F25),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    dividerColor: const Color(0xFF1E2830),
    dividerTheme: const DividerThemeData(color: Color(0xFF1E2830), thickness: 1),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
    ),
  );
 
  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: const Color(0xFF1D9E75),
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF1D9E75),
      secondary: Color(0xFF00D2FD),
      surface: Colors.white,
      onSurface: Color(0xFF1E293B),
      onSurfaceVariant: Color(0xFF64748B),
      outline: Color(0xFFE2E8F0),
    ),
    cardColor: Colors.white,
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    dividerColor: const Color(0xFFE2E8F0),
    dividerTheme: const DividerThemeData(color: Color(0xFFE2E8F0), thickness: 1),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Color(0xFF1E293B)),
      titleTextStyle: TextStyle(color: Color(0xFF1E293B), fontSize: 20, fontWeight: FontWeight.bold),
    ),
  );
}
