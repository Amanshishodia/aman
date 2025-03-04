import 'package:flutter/services.dart';

class RotationHelper {
  static const EventChannel _eventChannel =
      EventChannel('com.mercyott.app/rotation_listener');

  static Stream<bool> get autoRotateStream {
    return _eventChannel.receiveBroadcastStream().map((event) => event as bool);
  }
}
