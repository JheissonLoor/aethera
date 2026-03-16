import 'package:flutter/material.dart';

abstract class AetheraMotion {
  static const Duration micro = Duration(milliseconds: 110);
  static const Duration short = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration emphasized = Duration(milliseconds: 420);
  static const Duration screen = Duration(milliseconds: 520);
  static const Duration screenSlow = Duration(milliseconds: 620);
  static const Duration sheet = Duration(milliseconds: 320);
  static const Duration long = Duration(milliseconds: 900);
  static const Duration stagger = Duration(milliseconds: 120);

  static const Curve standard = Curves.easeInOutCubic;
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve emphasis = Curves.easeOutBack;
  static const Curve fade = Curves.easeInOut;
}
