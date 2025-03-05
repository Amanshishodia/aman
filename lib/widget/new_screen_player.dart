import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

class NewScreenPlayer extends StatefulWidget {
  final String videoUrl;
  final bool isLiveStream;

  const NewScreenPlayer({
    super.key,
    required this.videoUrl,
    this.isLiveStream = false,
  });

  @override
  _NewScreenPlayerState createState() => _NewScreenPlayerState();
}

class _NewScreenPlayerState extends State<NewScreenPlayer> with WidgetsBindingObserver {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _isFullScreen = false;
  Orientation? _lastOrientation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Allow all orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _initializePlayer();
  }

  @override
  void didChangeMetrics() {
    // Use a post-frame callback to ensure the latest context and metrics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final mediaQuery = MediaQuery.of(context);
      final currentOrientation = mediaQuery.orientation;

      // Only react if orientation has actually changed
      if (_lastOrientation != currentOrientation) {
        _handleOrientationChange(currentOrientation);
        _lastOrientation = currentOrientation;
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

  void _initializePlayer() async {
    try {
      // Safely dispose existing controllers
      await _disposeControllers();

      // Create a new video player controller
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      // Initialize the controller
      await _videoPlayerController!.initialize();

      // Check if widget is still mounted
      if (!mounted) {
        await _disposeControllers();
        return;
      }

      // Create Chewie controller with robust configuration
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: true,
          looping: false,
          aspectRatio: _videoPlayerController!.value.aspectRatio,
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
        _isInitialized = true;
      });

      // Check current orientation on initialization
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final mediaQuery = MediaQuery.of(context);
        _lastOrientation = mediaQuery.orientation;

        if (mediaQuery.orientation == Orientation.landscape) {
          _enterFullScreen();
        }
      });
    } catch (e) {
      print('Error initializing video player: $e');
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  void _enterFullScreen() {
    if (_chewieController != null && !_chewieController!.isFullScreen) {
      try {
        _chewieController!.enterFullScreen();
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        setState(() {
          _isFullScreen = true;
        });
      } catch (e) {
        print('Error entering full screen: $e');
      }
    }
  }

  void _exitFullScreen() {
    if (_chewieController != null && _chewieController!.isFullScreen) {
      try {
        _chewieController!.exitFullScreen();
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        );
        setState(() {
          _isFullScreen = false;
        });
      } catch (e) {
        print('Error exiting full screen: $e');
      }
    }
  }

  void _toggleFullScreen() {
    if (_chewieController == null) return;

    if (_chewieController!.isFullScreen) {
      _exitFullScreen();
    } else {
      _enterFullScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        // Video Player
        Center(
          child: _chewieController != null
              ? Chewie(controller: _chewieController!)
              : const CircularProgressIndicator(),
        ),

        // Manual Full Screen Button
        Positioned(
          bottom: 10,
          right: 10,
          child: IconButton(
            icon: Icon(
              _chewieController!.isFullScreen
                  ? Icons.fullscreen_exit
                  : Icons.fullscreen,
              color: Colors.white,
            ),
            onPressed: _toggleFullScreen,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeControllers();

    // Reset to default orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    super.dispose();
  }

  Future<void> _disposeControllers() async {
    try {
      if (_videoPlayerController != null) {
        await _videoPlayerController!.dispose();
        _videoPlayerController = null;
      }

      if (_chewieController != null) {
        _chewieController!.dispose();
        _chewieController = null;
      }
    } catch (e) {
      print('Error during controller disposal: $e');
    }
  }
}