import 'package:flutter/material.dart';
import 'package:mercy_tv_app/API/api_integration.dart';

class LiveViewWidget extends StatefulWidget {
  const LiveViewWidget({super.key});

  @override
  State<LiveViewWidget> createState() => _LiveViewWidgetState();
}

class _LiveViewWidgetState extends State<LiveViewWidget> {
  final ApiIntegration apiIntegration = ApiIntegration();
  late Future<String?> _liveViewFuture;

  @override
  void initState() {
    super.initState();
    _liveViewFuture = apiIntegration.liveView();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _liveViewFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(); // Don't show anything while loading
        } else if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
          return const SizedBox(); // Hide widget if response is null or empty
        } else {
          final views = snapshot.data!;

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 0.5),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.remove_red_eye,
                    color: Colors.white,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    views,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
