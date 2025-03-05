import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
  Rx<Orientation> currentOrientation = Orientation.portrait.obs;
  RxBool showButton = false.obs;
  RxBool isLiveStreamVar = true.obs;
  Rx<int?> currentlyPlayingIndex = Rx<int?>(null);

  VideoPlayerController? videoPlayerController;
  ChewieController? chewieController;
  RxBool isVideoInitialized = false.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    videoPlayerController?.dispose();
    chewieController?.dispose();
    super.onClose();
  }

  @override
  void didChangeMetrics() {
    if (Get.context == null) return;

    final mediaQuery = MediaQuery.of(Get.context!);
    final orientation = mediaQuery.orientation;

    // Check if orientation has changed
    if (orientation != currentOrientation.value) {
      currentOrientation.value = orientation;

      // Automatically enter full screen when rotated to landscape
      if (orientation == Orientation.landscape) {
        _enterFullScreen();
      } else if (orientation == Orientation.portrait) {
        _exitFullScreen();
      }
    }
  }

  void _enterFullScreen() {
    if (chewieController != null && !chewieController!.isFullScreen) {
      try {
        // Explicitly enter full screen
        chewieController!.enterFullScreen();

        // Hide system UI
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

        // Set orientation preferences for landscape
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } catch (e) {
        print('Error entering full screen: $e');
      }
    }
  }

  void _exitFullScreen() {
    if (chewieController != null && chewieController!.isFullScreen) {
      try {
        // Explicitly exit full screen
        chewieController!.exitFullScreen();

        // Restore system UI
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        );

        // Reset orientation preferences to portrait
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      } catch (e) {
        print('Error exiting full screen: $e');
      }
    }
  }

  void initializePlayer(String videoUrl, bool isLive) {
    // Dispose existing controllers if they exist
    videoPlayerController?.dispose();
    chewieController?.dispose();

    videoPlayerController = VideoPlayerController.network(videoUrl);

    videoPlayerController?.initialize().then((_) {
      chewieController = ChewieController(
        videoPlayerController: videoPlayerController!,
        autoPlay: true,
        looping: false,
        aspectRatio: videoPlayerController!.value.aspectRatio,
        showControls: true,
        allowFullScreen: true,
        deviceOrientationsOnEnterFullScreen: [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ],
        deviceOrientationsAfterFullScreen: [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ],
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Error loading video: $errorMessage',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
        placeholder: const Center(child: CircularProgressIndicator()),
        autoInitialize: true,
      );

      isVideoInitialized.value = true;
      isLiveStreamVar.value = isLive;
      update();
    });
  }

  void onScreenTapped() {
    showButton.value = !showButton.value;
  }
}