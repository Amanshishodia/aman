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

    // Allow all orientations initially
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeControllers();

    // Reset to default orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    super.onClose();
  }

  @override
  void didChangeMetrics() {
    if (Get.context == null) return;

    // Use a post-frame callback to ensure the latest context and metrics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.context == null) return;

      final mediaQuery = MediaQuery.of(Get.context!);
      final orientation = mediaQuery.orientation;

      // Only react if orientation has actually changed
      if (orientation != currentOrientation.value) {
        currentOrientation.value = orientation;
        _handleOrientationChange(orientation);
      }
    });
  }

  void _handleOrientationChange(Orientation orientation) {
    if (orientation == Orientation.landscape) {
      _enterFullScreen();
    } else {
      _exitFullScreen();
    }
  }

  void _enterFullScreen() {
    if (chewieController != null && !chewieController!.isFullScreen) {
      try {
        chewieController!.enterFullScreen();
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } catch (e) {
        print('Error entering full screen: $e');
      }
    }
  }

  void _exitFullScreen() {
    if (chewieController != null && chewieController!.isFullScreen) {
      try {
        chewieController!.exitFullScreen();
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        );
      } catch (e) {
        print('Error exiting full screen: $e');
      }
    }
  }

  void toggleFullScreen() {
    if (chewieController == null) return;

    if (chewieController!.isFullScreen) {
      _exitFullScreen();
    } else {
      _enterFullScreen();
    }
  }

  void initializePlayer(String videoUrl, bool isLive) async {
    try {
      // Dispose existing controllers
      await _disposeControllers();

      // Create a new video player controller
      videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
      );

      // Initialize the controller
      await videoPlayerController!.initialize();

      // Create Chewie controller with robust configuration
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
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
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

      // Check current orientation on initialization
      if (Get.context != null) {
        final mediaQuery = MediaQuery.of(Get.context!);
        if (mediaQuery.orientation == Orientation.landscape) {
          _enterFullScreen();
        }
      }
    } catch (e) {
      print('Error initializing video player: $e');
      isVideoInitialized.value = false;
      update();
    }
  }

  Future<void> _disposeControllers() async {
    try {
      if (videoPlayerController != null) {
        await videoPlayerController!.dispose();
        videoPlayerController = null;
      }

      if (chewieController != null) {
        chewieController!.dispose();
        chewieController = null;
      }
    } catch (e) {
      print('Error during controller disposal: $e');
    }
  }

  void onScreenTapped() {
    showButton.value = !showButton.value;
  }
}