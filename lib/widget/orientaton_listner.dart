import 'package:flutter/material.dart';

class OrientationListenerWidget extends StatefulWidget {
  final Widget child;
  final Function(Orientation) onOrientationChange;

  const OrientationListenerWidget({
    super.key,
    required this.child,
    required this.onOrientationChange,
  });

  @override
  _OrientationListenerWidgetState createState() => _OrientationListenerWidgetState();
}

class _OrientationListenerWidgetState extends State<OrientationListenerWidget> with WidgetsBindingObserver {
  Orientation? _lastOrientation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastOrientation = MediaQueryData.fromView(WidgetsBinding.instance.window).orientation;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    Orientation newOrientation = MediaQueryData.fromView(WidgetsBinding.instance.window).orientation;

    if (_lastOrientation != newOrientation) {
      _lastOrientation = newOrientation;
      widget.onOrientationChange(newOrientation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
}
}