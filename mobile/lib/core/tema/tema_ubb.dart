import 'package:flutter/material.dart';

import 'colores_ubb.dart';

ThemeData crearTemaUbb() {
  const esquema = ColorScheme(
    brightness: Brightness.light,
    primary: ColoresUbb.azulInstitucional,
    onPrimary: Colors.white,
    secondary: ColoresUbb.amarilloInstitucional,
    onSecondary: ColoresUbb.azulOscuro,
    error: ColoresUbb.rojoInstitucional,
    onError: Colors.white,
    surface: ColoresUbb.superficie,
    onSurface: ColoresUbb.textoPrincipal,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: ColoresUbb.fondo,
    appBarTheme: const AppBarTheme(
      backgroundColor: ColoresUbb.azulInstitucional,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: ColoresUbb.superficie,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: ColoresUbb.borde),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.92),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: ColoresUbb.borde),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: ColoresUbb.borde),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: ColoresUbb.azulInstitucional,
          width: 1.4,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColoresUbb.azulInstitucional,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: ColoresUbb.azulInstitucional,
      indicatorColor: ColoresUbb.amarilloInstitucional,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          color: Colors.white.withValues(
            alpha: states.contains(WidgetState.selected) ? 1 : 0.78,
          ),
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected)
              ? ColoresUbb.azulOscuro
              : Colors.white.withValues(alpha: 0.82),
        );
      }),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ColoresUbb.azulInstitucional,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: ColoresUbb.azulInstitucional),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}
