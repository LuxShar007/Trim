import 'package:flutter/material.dart';

/// Border radius tokens for TRIM.
class AppRadius {
  AppRadius._();

  static const double smVal = 8.0;
  static const double mdVal = 12.0;
  static const double lgVal = 16.0;
  static const double xlVal = 20.0;
  static const double pillVal = 999.0;

  static final BorderRadius sm = BorderRadius.circular(smVal);
  static final BorderRadius md = BorderRadius.circular(mdVal);
  static final BorderRadius lg = BorderRadius.circular(lgVal);
  static final BorderRadius xl = BorderRadius.circular(xlVal);
  static final BorderRadius pill = BorderRadius.circular(pillVal);
}
