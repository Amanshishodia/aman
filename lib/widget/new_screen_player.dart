import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mercy_tv_app/controllers/home_controller.dart';

class NewScreenPlayer extends StatefulWidget {
  final String? videoUrl;
  final bool isLiveStream;

  const NewScreenPlayer({
    super.key,
    this.videoUrl,
    this.isLiveStream = false,
  });

  @override
  State<NewScreenPlayer> createState() => _NewScreenPlayerState();
}

class _NewScreenPlayerState extends State<NewScreenPlayer> {
  late final HomeController homeController;

  @override
  void initState() {
    super.initState();
    homeController = Get.put(HomeController());

    // Initialize with provided URL or default to live stream
    if (widget.videoUrl != null) {
      homeController.initializePlayer(widget.videoUrl!, widget.isLiveStream);
    } else if (widget.isLiveStream) {
      homeController.initializePlayer('https://mercyott.com/hls_output/master.m3u8', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video player
          GetBuilder<HomeController>(
            builder: (controller) => controller.isVideoInitialized.value &&
                controller.chewieController != null
                ? Chewie(controller: controller.chewieController!)
                : const Center(child: CircularProgressIndicator()),
          ),

          // Tap detector for showing/hiding controls
          Listener(
            onPointerDown: (_) => homeController.onScreenTapped(),
            behavior: HitTestBehavior.translucent,
          ),

          // Live button
          Obx(
                () => homeController.showButton.value
                ? Positioned(
              bottom: 40,
              right: 20,
              child: _liveButton(
                homeController.isLiveStreamVar.value ? 'Live' : 'Go Live',
                homeController.isLiveStreamVar.value
                    ? Colors.red
                    : const Color(0xFF8DBDCC),
                    () {
                  homeController.currentlyPlayingIndex?.value = -1;
                  homeController.initializePlayer(
                      'https://mercyott.com/hls_output/master.m3u8', true);
                },
              ),
            )
                : const SizedBox.shrink(),
          )
        ],
      ),
    );
  }

  Widget _liveButton(String text, Color color, VoidCallback onPressed) {
    return Container(
      height: 20,
      width: 50,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        child: Text(text,
            style: const TextStyle(color: Colors.white, fontSize: 11)),
      ),
    );
  }
}