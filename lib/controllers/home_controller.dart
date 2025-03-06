import 'dart:async';
import 'dart:developer';

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

  bool _isDisposed = false;
  Timer? _hideButtonTimer;
  int _playerInitToken = 0;
  String _currentVideoUrl = 'https://mercyott.com/hls_output/master.m3u8';

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

    // Initialize player with default URL
    initializePlayer(_currentVideoUrl, true);
  }

  @override
  void onClose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _disposeControllers();
    _hideButtonTimer?.cancel();

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
      if (Get.context == null || _isDisposed) return;

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

  Future<void> initializePlayer(String videoUrl, bool isLiveStream) async {
    await _disposeControllers();

    final int currentToken = ++_playerInitToken;
    _currentVideoUrl = videoUrl;

    try {
      // Create a new video player controller with appropriate options for live streaming
      videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        videoPlayerOptions: isLiveStream
            ? VideoPlayerOptions(mixWithOthers: true, allowBackgroundPlayback: true)
            : null,
      );

      // Initialize the controller
      await videoPlayerController!.initialize();

      // Check if still valid (not disposed or superseded by another initialization)
      if (_isDisposed || currentToken != _playerInitToken) return;

      // Create Chewie controller with robust configuration
      chewieController = ChewieController(
        videoPlayerController: videoPlayerController!,
        autoPlay: true,
        looping: false,
        aspectRatio: videoPlayerController!.value.aspectRatio,
        showControls: true,
        allowFullScreen: true,
        allowPlaybackSpeedChanging: !isLiveStream,
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
        additionalOptions: (context) {
          if (isLiveStream && !(chewieController?.isFullScreen ?? false)) {
            return <OptionItem>[
              OptionItem(
                iconData: Icons.video_settings,
                title: 'Quality',
                onTap: (context) => _showQualityOptions(context),
              )
            ];
          }
          return [];
        },
      );

      isVideoInitialized.value = true;
      isLiveStreamVar.value = isLiveStream;

      // If it's a live stream, ensure it's playing
      if (isLiveStream) {
        videoPlayerController!.play();
      }

      update();

      // Check current orientation on initialization
      if (!_isDisposed && Get.context != null) {
        final mediaQuery = MediaQuery.of(Get.context!);
        if (mediaQuery.orientation == Orientation.landscape) {
          _enterFullScreen();
        }
      }
    } catch (e) {
      if (currentToken == _playerInitToken && !_isDisposed) {
        isVideoInitialized.value = false;
        update();
      }
      print('Error initializing video player: $e');
    }
  }

  void _showQualityOptions(BuildContext context) {
    if (_isDisposed) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      builder: (BuildContext context) {
        return Wrap(
          children: [
            _qualityOption(
                context, 'Auto', 'https://mercyott.com/hls_output/master.m3u8'),
            _qualityOption(
                context, '360p', 'https://mercyott.com/hls_output/360p.m3u8'),
            _qualityOption(
                context, '720p', 'https://mercyott.com/hls_output/720p.m3u8'),
            _qualityOption(
                context, '1080p', 'https://mercyott.com/hls_output/1080p.m3u8'),
          ],
        );
      },
    );
  }

  Widget _qualityOption(BuildContext context, String quality, String url) {
    return ListTile(
      leading: const Icon(Icons.hd, color: Colors.white),
      title: Text(quality, style: const TextStyle(color: Colors.white)),
      onTap: () => _changeVideoQuality(url),
    );
  }

  Future<void> _changeVideoQuality(String videoUrl) async {
    // Close quality bottom sheet if open
    Get.back();
    log('Changing quality to: $videoUrl');

    // Allow a brief delay for UI to settle
    await Future.delayed(const Duration(milliseconds: 200));

    // Initialize with new quality URL, maintaining live stream state
    initializePlayer(videoUrl, true);
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

      isVideoInitialized.value = false;
    } catch (e) {
      print('Error during controller disposal: $e');
    }
  }

  void onScreenTapped() {
    showButton.value = true;

    // Auto-hide the button after a delay
    _hideButtonTimer?.cancel();
    _hideButtonTimer = Timer(const Duration(seconds: 4), () {
      if (!_isDisposed) {
        showButton.value = false;
      }
    });
  }
}