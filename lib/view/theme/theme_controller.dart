import 'package:flutter/material.dart';

/// Global theme mode notifier. Profile screen flips this; MaterialApp listens.
final ValueNotifier<ThemeMode> themeController =
    ValueNotifier<ThemeMode>(ThemeMode.light);
