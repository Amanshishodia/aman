import 'dart:async';
import 'dart:developer';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class HomeController extends GetxController {
  VideoPlayerController? videoController;
  ChewieController? chewieController;

  RxBool _isVideoInitializedRx = false.obs;
  bool get isVideoInitialized => _isVideoInitializedRx.value;
  set isVideoInitialized(bool value) => _isVideoInitializedRx.value = value;

  bool _isDisposed = false;
  RxInt? currentlyPlayingIndex = (-1).obs;

  RxBool showButton = false.obs;
  Timer? _hideButtonTimer;
  int _playerInitToken = 0;
  String _currentVideoUrl = 'https://mercyott.com/hls_output/master.m3u8';
  RxBool isLiveStreamVar = true.obs;

  Rx<Orientation> currentOrientation = Orientation.portrait.obs;

  Future<void> initializePlayer(String videoUrl, bool isLiveStream) async {
    _disposeControllers();

    // Update the current video URL
    _currentVideoUrl = videoUrl;

    final int currentToken = ++_playerInitToken;

    try {
      videoController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        videoPlayerOptions: isLiveStream
            ? VideoPlayerOptions(
            mixWithOthers: true, allowBackgroundPlayback: true)
            : null,
      );

      await videoController!.initialize();

      if (!_isDisposed && currentToken == _playerInitToken) {
        isLiveStreamVar.value = isLiveStream;
        isVideoInitialized = true;
        _setupChewieController();
        if (isLiveStream) {
          videoController!.play();
        }
      }
    } catch (e) {
      if (currentToken == _playerInitToken) {
        isVideoInitialized = false;
      }
      print("Error initializing video: $e");
    }
  }

  void _setupChewieController() {
    if (videoController == null || !videoController!.value.isInitialized) {
      return;
    }

    chewieController = ChewieController(
      videoPlayerController: videoController!,
      aspectRatio: videoController!.value.aspectRatio,
      autoPlay: true,
      looping: false,
      showControls: true,
      allowFullScreen: true,
      allowPlaybackSpeedChanging: !isLiveStreamVar.value,
      isLive: isLiveStreamVar.value,
      fullScreenByDefault: false,
      additionalOptions: (context) {
        if (isLiveStreamVar.value &&
            !(chewieController?.isFullScreen ?? false)) {
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

    // Save current position if not a live stream
    Duration? position;
    if (!isLiveStreamVar.value && videoController != null) {
      position = videoController!.value.position;
    }

    // Keep track of fullscreen state
    bool wasFullScreen = chewieController?.isFullScreen ?? false;

    // Initialize with new URL
    await initializePlayer(videoUrl, isLiveStreamVar.value);

    // If not a live stream, seek to the previous position
    if (!isLiveStreamVar.value && position != null && videoController != null) {
      await videoController!.seekTo(position);
    }

    // Restore fullscreen state if needed
    if (wasFullScreen && chewieController != null && !chewieController!.isFullScreen) {
      chewieController!.enterFullScreen();
    }
  }

  void _disposeControllers() {
    if (chewieController != null) {
      chewieController!.dispose();
      chewieController = null;
    }

    if (videoController != null) {
      videoController!.dispose();
      videoController = null;
    }

    isVideoInitialized = false;
  }

  void onScreenTapped() {
    showButton.value = true;

    _hideButtonTimer?.cancel();
    _hideButtonTimer = Timer(const Duration(seconds: 4), () {
      if (!_isDisposed) {
        showButton.value = false;
      }
    });
  }

  @override
  void onInit() {
    initializePlayer(_currentVideoUrl, isLiveStreamVar.value);
    super.onInit();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _disposeControllers();
    _hideButtonTimer?.cancel();
    super.dispose();
  }
}