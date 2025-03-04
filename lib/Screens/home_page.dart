import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mercy_tv_app/Colors/custom_color.dart';
import 'package:mercy_tv_app/controllers/home_controller.dart';
import 'package:mercy_tv_app/widget/Live_View_widget.dart';
import 'package:mercy_tv_app/widget/button_section.dart';
import 'package:mercy_tv_app/widget/new_screen_player.dart';
import 'package:mercy_tv_app/API/dataModel.dart';
import 'package:mercy_tv_app/widget/sugested_video_list.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  bool isFavorite = false;
  Timer? _timer;
  DateTime _currentDateTime = DateTime.now();
  String _currentVideoUrl = 'https://mercyott.com/hls_output/master.m3u8';
  bool _isLiveStream = true;
  String _selectedProgramTitle = 'Mercy TV Live';
  String _selectedProgramDate = '';
  String _selectedProgramTime = '';
  bool _isFullScreen = false;

  // Get HomeController instance
  HomeController get _homeController => Get.find<HomeController>();

  @override
  void initState() {
    super.initState();
    _startTimer();
    WakelockPlus.enable();

    // Initialize HomeController if not already
    if (!Get.isRegistered<HomeController>()) {
      Get.put(HomeController());
    }

    // Add observer to detect orientation changes
    WidgetsBinding.instance.addObserver(this);

    // Initialize the player after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _homeController.initializePlayer(_currentVideoUrl, true);

      // Listen to fullscreen changes from the player
      if (_homeController.chewieController != null) {
        _homeController.chewieController!.addListener(_onPlayerFullscreenChanged);
      }
    });
  }

  void _onPlayerFullscreenChanged() {
    if (_homeController.chewieController == null) return;

    final isFullScreen = _homeController.chewieController!.isFullScreen;

    if (_isFullScreen != isFullScreen && mounted) {
      setState(() {
        _isFullScreen = isFullScreen;
      });

      // Handle system UI based on fullscreen state
      if (isFullScreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual,
            overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]
        );
      }
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (mounted) {
      final orientation = MediaQuery.of(context).orientation;
      final isLandscape = orientation == Orientation.landscape;

      _handleOrientationChange(isLandscape);
    }
  }

  void _handleOrientationChange(bool isLandscape) {
    log("Orientation changed. Is landscape: $isLandscape");
    log("Current fullscreen state: ${_homeController.chewieController?.isFullScreen}");

    // Only update fullscreen state if needed
    if (isLandscape && !_homeController.isFullScreen.value) {
      // Enter fullscreen code
      _homeController.isFullScreen.value = true;
    } else if (!isLandscape && _homeController.isFullScreen.value) {
      // Exit fullscreen code
      _homeController.isFullScreen.value = false;
    }
  }

  // Toggle full screen method for fullscreen button
  void _toggleFullScreen() {
    if (_homeController.chewieController == null) return;

    if (_homeController.chewieController!.isFullScreen) {
      _homeController.chewieController!.exitFullScreen();
      setState(() {
        _isFullScreen = false;
      });
    } else {
      _homeController.chewieController!.enterFullScreen();
      setState(() {
        _isFullScreen = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    // If in landscape mode, show only the video player in fullscreen
    if (isLandscape) {
      return Scaffold(
        body: WillPopScope(
          onWillPop: () async {
            // When back button is pressed in landscape mode,
            // return to portrait orientation
            if (_homeController.chewieController != null &&
                _homeController.chewieController!.isFullScreen) {
              _homeController.chewieController!.exitFullScreen();
            }

            SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
            setState(() {
              _isFullScreen = false;
            });
            return false; // Don't actually pop, just change orientation
          },
          child: Container(
            color: Colors.black,
            child: Stack(
              children: [
                Center(
                  child: NewScreenPlayer(),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () {
                      // Exit landscape mode and return to portrait
                      if (_homeController.chewieController != null &&
                          _homeController.chewieController!.isFullScreen) {
                        _homeController.chewieController!.exitFullScreen();
                      }

                      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
                      setState(() {
                        _isFullScreen = false;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Regular portrait layout
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double baseFontSize = screenWidth < 360 ? 14 : 16;
    double titleFontSize = screenWidth < 360 ? 18 : 22;
    double buttonFontSize = screenWidth < 360 ? 16 : 20;

    double horizontalPadding = screenWidth * 0.04;
    double verticalSpacing = screenHeight * 0.015;

    String formattedDate = _selectedProgramDate.isNotEmpty
        ? _selectedProgramDate
        : DateFormat('EEE dd MMM').format(_currentDateTime);
    String formattedTime = _selectedProgramTime.isNotEmpty
        ? _selectedProgramTime
        : DateFormat('hh:mm a').format(_currentDateTime);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Color.fromARGB(255, 0, 90, 87),
              Color(0xFF000000),
            ],
            stops: [0.0, 0.9],
          ),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                SizedBox(
                  height: screenHeight * 0.3,
                  child: NewScreenPlayer(),
                ),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: IconButton(
                    icon: const Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: _toggleFullScreen,
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalSpacing,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: screenWidth * 0.75,
                            child: GestureDetector(
                              child: Text(
                                _selectedProgramTitle,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Mulish-Bold',
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                          if (_isLiveStream)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: verticalSpacing * 0.5),
                              child: const LiveViewWidget(),
                            ),
                        ],
                      ),
                      SizedBox(height: verticalSpacing),
                      Row(
                        children: [
                          Text(
                            formattedDate,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: baseFontSize,
                              fontFamily: 'Mulish-Medium',
                            ),
                          ),
                          SizedBox(width: horizontalPadding * 0.5),
                          const Text("|",
                              style: TextStyle(color: Colors.white)),
                          SizedBox(width: horizontalPadding * 0.5),
                          Text(
                            formattedTime,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: baseFontSize,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: verticalSpacing),
                      const ButtonSection(),
                      SizedBox(height: verticalSpacing * 2),
                      GestureDetector(
                        onTap: _launchURL,
                        child: Container(
                          height: screenHeight * 0.06,
                          width: screenWidth * 0.9,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                            BorderRadius.circular(screenWidth * 0.1),
                          ),
                          child: Center(
                            child: Text(
                              'Visit Website',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.normal,
                                fontFamily: 'Mulish-Medium',
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: verticalSpacing),
                      Text(
                        'Past Programs',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: baseFontSize + 2,
                          fontWeight: FontWeight.w300,
                          fontFamily: 'Mulish-Medium',
                        ),
                      ),
                      SizedBox(height: verticalSpacing * 0.5),
                      Container(
                        width: screenWidth * 0.35,
                        height: 2,
                        color: CustomColors.buttonColor,
                      ),
                      SuggestedVideoCard(
                        onVideoTap: _playVideo,
                      ),
                      SizedBox(height: verticalSpacing * 2),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);

    // Remove listener
    if (_homeController.chewieController != null) {
      _homeController.chewieController!.removeListener(_onPlayerFullscreenChanged);
    }

    // Reset orientation when disposing
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Make sure we exit fullscreen mode when disposing
    if (_homeController.chewieController != null &&
        _homeController.chewieController!.isFullScreen) {
      _homeController.chewieController!.exitFullScreen();
    }

    WakelockPlus.disable();

    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentDateTime = DateTime.now();
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://mercytv.tv');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  void _playVideo(ProgramDetails programDetails) {
    if (!mounted) return;
    setState(() {
      _currentVideoUrl = programDetails.videoUrl;
      _isLiveStream = false;
      _selectedProgramTitle = programDetails.title;

      // Initialize player with new video
      _homeController.initializePlayer(programDetails.videoUrl, false);

      if (programDetails.date != null && programDetails.date!.isNotEmpty) {
        try {
          DateTime parsedDate =
          DateFormat('yyyy-MM-dd').parse(programDetails.date!);
          _selectedProgramDate = DateFormat('EEE dd MMM').format(parsedDate);
        } catch (e) {
          _selectedProgramDate = programDetails.date!;
        }
      } else {
        _selectedProgramDate = '';
      }

      if (programDetails.time != null && programDetails.time!.isNotEmpty) {
        try {
          DateTime parsedTime =
          DateFormat('HH:mm:ss').parse(programDetails.time!);
          _selectedProgramTime = DateFormat('hh:mm a').format(parsedTime);
        } catch (e) {
          _selectedProgramTime = programDetails.time!;
        }
      } else {
        _selectedProgramTime = '';
      }
    });
  }
}