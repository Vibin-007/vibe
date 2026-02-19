import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/user_preferences_service.dart';
import 'package:light/light.dart';
import 'dart:async';

// Events
abstract class ThemeEvent {}
class ChangeTheme extends ThemeEvent {
  final ThemeMode mode;
  ChangeTheme(this.mode);
}
class ChangeAccentColor extends ThemeEvent {
  final Color color;
  ChangeAccentColor(this.color);
}
class LoadTheme extends ThemeEvent {}

// State
class ThemeState {
  final ThemeMode themeMode;
  final Color? accentColor;
  ThemeState(this.themeMode, {this.accentColor});
}

// Bloc
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final UserPreferencesService _prefs;

  ThemeBloc(this._prefs) : super(ThemeState(ThemeMode.system)) {
    on<LoadTheme>((event, emit) {
      final modeStr = _prefs.getThemeMode();
      final mode = modeStr == 'light' 
          ? ThemeMode.light 
          : modeStr == 'dark' 
              ? ThemeMode.dark 
              : ThemeMode.system;
      
      final colorVal = _prefs.getAccentColor();
      Color? color;
      if (colorVal != null) {
        color = Color(colorVal);
      }
      
      emit(ThemeState(mode, accentColor: color));
    });

    on<ChangeTheme>((event, emit) async {
      // Disable smart dark mode if enabled so it doesn't fight the user
      if (_prefs.getSmartDarkMode()) {
        await _prefs.setSmartDarkMode(false);
      }

      final modeStr = event.mode == ThemeMode.light 
          ? 'light' 
          : event.mode == ThemeMode.dark 
              ? 'dark' 
              : 'system';
      await _prefs.setThemeMode(modeStr);
      emit(ThemeState(event.mode, accentColor: state.accentColor));
    });

    on<ChangeAccentColor>((event, emit) async {
      await _prefs.setAccentColor(event.color.value);
      emit(ThemeState(state.themeMode, accentColor: event.color));
    });

    _initLightSensor();
  }

  StreamSubscription? _lightSubscription;
  DateTime _lastSwitch = DateTime.now();

  void _initLightSensor() {
    // Listen to pref changes to toggle sensor
    // Ideally we subscribe to prefs stream, but for now lets just start it if enabled.
    // Wait, we need to know when pref changes.
    // Hack: We can listen to dataStream from prefs to re-check.
    
    _prefs.dataStream.listen((_) {
       if (_prefs.getSmartDarkMode()) {
          _startLightSensor();
       } else {
          _stopLightSensor();
       }
    });

    if (_prefs.getSmartDarkMode()) {
      _startLightSensor();
    }
  }

  void _startLightSensor() {
    if (_lightSubscription != null) return;
    
    try {
      final Light light = Light();
      _lightSubscription = light.lightSensorStream.listen((int lux) {
         final now = DateTime.now();
         if (now.difference(_lastSwitch).inSeconds < 3) return; // Debounce

         // Thresholds
         if (lux < 10 && state.themeMode != ThemeMode.dark) {
            add(ChangeTheme(ThemeMode.dark));
            _lastSwitch = now;
         } else if (lux > 100 && state.themeMode != ThemeMode.light) {
            add(ChangeTheme(ThemeMode.light));
            _lastSwitch = now;
         }
      });
    } catch (e) {
      print("Light Sensor Error: $e");
    }
  }

  void _stopLightSensor() {
    _lightSubscription?.cancel();
    _lightSubscription = null;
  }

  @override
  Future<void> close() {
    _stopLightSensor();
    return super.close();
  }
}
