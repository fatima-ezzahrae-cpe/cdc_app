import 'package:flutter/material.dart';
import 'app_colors.dart';
class T {
  static TextStyle h1(Color c) => TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c);
  static TextStyle h2(Color c) => TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c);
  static TextStyle h3(Color c) => TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c);
  static TextStyle body(Color c) => TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: c, height: 1.5);
  static TextStyle bold(Color c) => TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c);
  static TextStyle small(Color c) => TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: c);
  static TextStyle label(Color c) => TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c, letterSpacing: 0.5);
  static TextStyle micro(Color c) => TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: c, letterSpacing: 0.3);
}
