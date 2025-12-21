import 'package:flutter/material.dart';

// Hilfsklassen für DatabaseStatusScreen (müssen außerhalb der State-Klasse sein)
@immutable
class LogEntry {
  final String message;
  final DateTime time;
  final LogType type;
  
  const LogEntry(this.message, this.time, {this.type = LogType.info});
  
  String get formattedTime => 
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}:'
      '${time.second.toString().padLeft(2, '0')}';
  
  Color get color {
    switch (type) {
      case LogType.success: return Color(0xFF00FF00); // Hellgrün
      case LogType.error: return Color(0xFFFF5555);   // Rot
      case LogType.warning: return Color(0xFFFFAA00); // Orange
      default: return Color(0xFF00AAFF);              // Blau
    }
  }
  
  String get prefix {
    switch (type) {
      case LogType.success: return '✅';
      case LogType.error: return '❌';
      case LogType.warning: return '⚠️';
      default: return '📊';
    }
  }
}

enum LogType { info, success, error, warning }
