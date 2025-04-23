import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:mercy_tv_app/API/api_integration.dart'; // Your API integration
import 'package:mercy_tv_app/API/dataModel.dart'; // Your data model

class HomeController extends GetxController with WidgetsBindingObserver {
  Rx<Orientation> currentOrientation = Orientation.portrait.obs;
  RxBool showButton = false.obs;
  RxBool isLiveStreamVar = true.obs;
  Rx<int?> currentlyPlayingIndex = Rx<int?>(null);

  VideoPlayerController? videoPlayerController;
  ChewieController? chewieController;
  RxBool isVideoInitialized = false.obs;

  // Pagination variables for suggested videos
  RxList<ProgramDetails> suggestedVideos = <ProgramDetails>[].obs; // List of videos
  RxBool isLoading = false.obs; // Loading state
  RxBool hasMore = true.obs; // Whether more data is available
  int pageSize = 6; // Load 6 videos at a time
  int currentPage = 0; // Current page number
  List<dynamic> _allVideoData = []; // Store all data locally if API doesn't paginate

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

    // Fetch initial batch of suggested videos
    fetchSuggestedVideos();
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

  // Fetch suggested videos with pagination
  Future<void> fetchSuggestedVideos() async {
    if (isLoading.value || !hasMore.value) return;

    isLoading.value = true;
    try {
      // Fetch data from API (modify this based on your API's pagination support)
      List<dynamic> newVideoData = await _fetchVideoData(currentPage, pageSize);

      if (newVideoData.isEmpty) {
        hasMore.value = false; // No more data to load
      } else {
        // Convert raw API data to ProgramDetails
        List<ProgramDetails> newVideos = newVideoData.map((video) {
          var program = video['program'] ?? {};
          return ProgramDetails(
            imageUrl: program['image'],
            date: program['date'],
            time: program['time'],
            title: program['program'] ?? 'Unknown Program',
            videoUrl: video['url'],
          );
        }).toList();

        suggestedVideos.addAll(newVideos);
        currentPage++;
      }
    } catch (e) {
      log('Error fetching videos: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch video data (with pagination if API supports it, otherwise local pagination)
  Future<List<dynamic>> _fetchVideoData(int page, int size) async {
    // Option 1: If your API supports pagination
    // Replace this with your actual paginated API call
    // Example: List<dynamic> data = await ApiIntegration().getVideoData(page: page, size: size);

    // Option 2: If your API doesn't support pagination, fetch all once and paginate locally
    if (_allVideoData.isEmpty) {
      _allVideoData = await ApiIntegration().getVideoData();
      _allVideoData.sort(
          (a, b) => int.parse(b['video_id']).compareTo(int.parse(a['video_id'])));
    }

    // Paginate locally
    int startIndex = page * size;
    if (startIndex >= _allVideoData.length) {
      return [];
    }
    int endIndex = startIndex + size;
    if (endIndex > _allVideoData.length) {
      endIndex = _allVideoData.length;
    }
    return _allVideoData.sublist(startIndex, endIndex);
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
        log('Error entering full screen: $e');
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
        log('Error exiting full screen: $e');
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
      videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        videoPlayerOptions: isLiveStream
            ? VideoPlayerOptions(mixWithOthers: true, allowBackgroundPlayback: true)
            : null,
      );

      await videoPlayerController!.initialize();

      if (_isDisposed || currentToken != _playerInitToken) return;

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

      if (isLiveStream) {
        videoPlayerController!.play();
      }

      update();

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
      log('Error initializing video player: $e');
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
    Get.back();
    log('Changing quality to: $videoUrl');

    await Future.delayed(const Duration(milliseconds: 200));
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
      log('Error during controller disposal: $e');
    }
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
}