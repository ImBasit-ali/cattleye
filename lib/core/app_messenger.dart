import 'package:flutter/material.dart';

/// Global scaffold messenger for app-wide snackbars (e.g. detection alerts).
class AppMessenger {
  AppMessenger._();

  static final GlobalKey<ScaffoldMessengerState> key =
      GlobalKey<ScaffoldMessengerState>();

  static ScaffoldMessengerState? get messenger => key.currentState;
}
