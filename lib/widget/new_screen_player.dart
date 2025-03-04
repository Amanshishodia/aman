import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mercy_tv_app/controllers/home_controller.dart';

class NewScreenPlayer extends StatelessWidget {
  const NewScreenPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController homeController = Get.put(HomeController());
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          homeController.isVideoInitialized &&
                  homeController.chewieController != null
              ? Chewie(controller: homeController.chewieController!)
              : const Center(child: CircularProgressIndicator()),
          Listener(
            onPointerDown: (_) => homeController.onScreenTapped(),
            behavior: HitTestBehavior.translucent,
          ),
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
                : SizedBox.shrink(),
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
