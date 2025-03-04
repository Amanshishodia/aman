import 'package:flutter/material.dart';

class LiveButtonWidget extends StatefulWidget {
  final bool isLiveStream;
  final VoidCallback onLiveButtonPressed;

  const LiveButtonWidget({
    Key? key,
    required this.isLiveStream,
    required this.onLiveButtonPressed,
  }) : super(key: key);

  @override
  State<LiveButtonWidget> createState() => _LiveButtonWidgetState();
}

class _LiveButtonWidgetState extends State<LiveButtonWidget> {
  bool _showButton = true;
  late final _hideButtonTimer;

  @override
  void initState() {
    super.initState();
    _startHideButtonTimer();
  }

  void _startHideButtonTimer() {
    _hideButtonTimer?.cancel();
    _hideButtonTimer = Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showButton = false;
        });
      }
    });
  }

  void _onTap() {
    setState(() {
      _showButton = true;
    });
    _startHideButtonTimer();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _showButton ? 1 : 0,
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            margin: const EdgeInsets.only(left: 16, top: 16),
            height: 24,
            width: 60,
            decoration: BoxDecoration(
              color: widget.isLiveStream ? Colors.red : const Color(0xFF8DBDCC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextButton(
              onPressed: widget.onLiveButtonPressed,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(
                widget.isLiveStream ? 'Live' : 'Go Live',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hideButtonTimer?.cancel();
    super.dispose();
  }
}
