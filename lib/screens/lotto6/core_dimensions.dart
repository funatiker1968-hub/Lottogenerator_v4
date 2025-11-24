import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
///  DIMENSIONEN – zentrale Größen & Proportionen für Lotto 6aus49 UI
/// ---------------------------------------------------------------------------

class LottoDim {
  /// Höhe des Superzahl-Bereichs (Kugel + Leiste + Startbutton)
  /// Fix 15% der Bildschirmhöhe, wie zuvor definiert.
  static double superRowHeight(BuildContext ctx)
      => MediaQuery.of(ctx).size.height * 0.15;

  /// Kugel-Größe (Superzahl) – jetzt plastischer & größer
  /// 80 war die Basis – jetzt 90 für bessere Sichtbarkeit
  static const double superBallSize = 90;

  /// Abstand zwischen Kugel – Leiste – Button (konstant)
  static const double superRowSpacing = 12;

  /// Größe der Ziffern in der Kugel
  static const double superBallFontSize = 38;

  /// Grid-Proportionen (7×7 Zahlenfeld)
  static const int gridColumns = 7;
  static const double gridSpacing = 1.5;
  static const double gridAspectRatio = 0.90;

  /// Tippkarten-Kartenradius
  static const double tipCardRadius = 10;

  /// Snake-Element-Dimensionen
  static const double snakeHeadSize = 34;
  static const double snakeTailSize = 30;
  static const double snakeNumberPaddingH = 8;
  static const double snakeNumberPaddingV = 4;

  /// Snake – Abstand zwischen Segmenten
  static const double snakeGap = 6;

  /// Snake – Höhe der finalen Snake-Leiste unter dem Tippfeld
  static const double snakeBarHeight = 44;

  /// Abstand zwischen Tippkarte und Snake-Leiste
  static const double snakeBarTopMargin = 6;

  /// Taskleiste (Mute + Buttons)
  static double taskbarHeight(BuildContext ctx)
      => MediaQuery.of(ctx).size.height * 0.08;

  /// Taskleiste – Icongröße
  static const double taskbarIconSize = 28;

  /// Buttons in Taskleiste – Höhe
  static const double taskButtonHeight = 48;

  /// Buttons in Taskleiste – Radius
  static const double taskButtonRadius = 10;
}
