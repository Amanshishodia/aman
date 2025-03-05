import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class RotationHelper {
  static final StreamController<bool> _autoRotateController =
  StreamController<bool>.broadcast(sync: true);

  static Stream<bool> get autoRotateStream => _autoRotateController.stream;

  static void setAutoRotate(bool enable) {
    _autoRotateController.add(enable);
  }

  static Stream<Orientation> detectOrientation() async* {
    await for (bool autoRotateOn in autoRotateStream) {
      log("Auto-rotate stream emitted: $autoRotateOn");
      if (!autoRotateOn) {
        log("Auto-rotate is OFF, ignoring orientation changes.");
        continue;
      }

      await for (AccelerometerEvent event in accelerometerEventStream()) {
        log("Accelerometer Event: x=${event.x}, y=${event.y}, z=${event.z}");
        double x = event.x; // Horizontal tilt
        double y = event.y; // Vertical tilt
        double z = event.z; // Flat detection

        // Ignore changes if the device is lying flat
        if (z.abs() > 8) {
          log("Device is flat, ignoring orientation change.");
          continue;
        }

        if (y.abs() > x.abs()) {
          yield Orientation.portrait;
        } else {
          yield Orientation.landscape;
        }
      }
    }
  }
}