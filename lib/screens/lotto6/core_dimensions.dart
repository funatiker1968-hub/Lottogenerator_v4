import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
///  DIMENSIONEN – zentrale Größen & Proportionen für Lotto 6aus49 UI
/// ---------------------------------------------------------------------------

class LottoDim {
  /// Höhe des Superzahl-Bereichs (Kugel + Leiste + Startbutton)
  /// Weißes Feld um exakt eine Kugelhöhe reduziert
  static double superRowHeight(BuildContext ctx)
      => (MediaQuery.of(ctx).size.height * 0.15) - superBallSize;

  /// Kugel-Größe (Superzahl)
  static const double superBallSize = 90;

  /// Abstand zwischen Kugel – Leiste – Button
  static const double superRowSpacing = 12;

  /// Größe der Ziffern in der Kugel
  static const double superBallFontSize = 38;

  /// Grid-Proportionen (7×7 Zahlenfeld)
  static const int gridColumns = 7;
  static const double gridSpacing = 1.5;
  static const double gridAspectRatio = 0.90;

  /// Tippkarten
  static const double tipCardRadius = 10;

  /// Snake-Elemente
  static const double snakeHeadSize = 34;
  static const double snakeTailSize = 30;
  static const double snakeNumberPaddingH = 8;
  static const double snakeNumberPaddingV = 4;
  static const double snakeGap = 6;

  /// Snake-Leiste
  static const double snakeBarHeight = 44;
  static const double snakeBarTopMargin = 6;

  /// Taskleiste
  static double taskbarHeight(BuildContext ctx)
      => MediaQuery.of(ctx).size.height * 0.08;

  static const double taskbarIconSize = 28;
  static const double taskButtonHeight = 48;
  static const double taskButtonRadius = 10;
}
