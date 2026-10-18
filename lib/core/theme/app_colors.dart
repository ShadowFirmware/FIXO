import 'package:flutter/material.dart';

/// Paleta de colores de FIXO.
abstract final class AppColors {
  // Paleta base
  /// Color de identidad: botones principales, enlaces, íconos activos y
  /// elementos seleccionados.
  static const Color primary = Color(0xFF0645D5);

  /// Profundidad y confianza: barra de navegación, encabezados, textos
  /// destacados y estados activos.
  static const Color navy = Color(0xFF082C91);

  /// Energía y atención visual: botones secundarios, notificaciones,
  /// etiquetas y acciones importantes.
  static const Color orange = Color(0xFFFF9008);

  /// Fondo de pantallas, tarjetas, formularios y ventanas modales.
  static const Color white = Color(0xFFFFFFFF);

  /// Fondo alternativo, secciones, campos de entrada y áreas de contenido.
  static const Color lightGray = Color(0xFFF3F6FC);

  /// Texto principal, descripciones, etiquetas y títulos sobre fondos claros.
  static const Color darkGray = Color(0xFF27344D);

  // Alias semánticos
  static const Color secondary = orange;
  static const Color background = white;
  static const Color surface = white;
  static const Color surfaceAlt = lightGray;
  static const Color inputFill = lightGray;
  static const Color textPrimary = darkGray;
  static const Color textSecondary = Color(0xB327344D); // darkGray al 70 %
  static const Color textOnPrimary = white;
  static const Color border = Color(0xFFD6DCE8);
  static const Color error = Color(0xFFD32F2F);
}
