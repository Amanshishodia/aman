import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mercy_tv_app/Colors/custom_color.dart';
import 'package:mercy_tv_app/controllers/home_controller.dart';
import 'package:mercy_tv_app/controllers/rotation_helper.dart';
import 'package:mercy_tv_app/widget/Live_View_widget.dart';
import 'package:mercy_tv_app/widget/button_section.dart';
import 'package:mercy_tv_app/widget/new_screen_player.dart';
import 'package:mercy_tv_app/API/dataModel.dart';
import 'package:mercy_tv_app/widget/sugested_video_list.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeController homeController = Get.put(HomeController());
  Timer? _timer;
  DateTime _currentDateTime = DateTime.now();
  String _currentVideoUrl = 'https://mercyott.com/hls_output/master.m3u8';
  bool _isLiveStream = true;
  String _selectedProgramTitle = 'Mercy TV Live';
  String _selectedProgramDate = '';
  String _selectedProgramTime = '';
  StreamSubscription? _orientationSubscription;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WakelockPlus.enable();
    _startOrientationListener();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _orientationSubscription?.cancel();
    homeController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentDateTime = DateTime.now();
        });
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
      homeController.initializePlayer(programDetails.videoUrl, false);

      try {
        if (programDetails.date != null && programDetails.date!.isNotEmpty) {
          DateTime parsedDate = DateFormat('yyyy-MM-dd').parse(programDetails.date!);
          _selectedProgramDate = DateFormat('EEE dd MMM').format(parsedDate);
        } else {
          _selectedProgramDate = '';
        }

        if (programDetails.time != null && programDetails.time!.isNotEmpty) {
          DateTime parsedTime = DateFormat('HH:mm:ss').parse(programDetails.time!);
          _selectedProgramTime = DateFormat('hh:mm a').format(parsedTime);
        } else {
          _selectedProgramTime = '';
        }
      } catch (e) {
        log('Error parsing date/time: $e');
        _selectedProgramDate = programDetails.date ?? '';
        _selectedProgramTime = programDetails.time ?? '';
      }
    });
  }

  void _startOrientationListener() {
    _orientationSubscription = RotationHelper.autoRotateStream.listen((autoRotateOn) {
      if (!autoRotateOn) return;

      accelerometerEventStream().listen((AccelerometerEvent event) {
        double x = event.x;
        double y = event.y;
        double z = event.z;

        if (z.abs() > 8) return; // Ignore if device is flat

        Orientation newOrientation = (y.abs() > x.abs()) ? Orientation.portrait : Orientation.landscape;

        if (homeController.currentOrientation.value != newOrientation) {
          homeController.currentOrientation.value = newOrientation;

          if (newOrientation == Orientation.landscape) {
            homeController.chewieController?.enterFullScreen();
          } else {
            homeController.chewieController?.exitFullScreen();
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
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
            // Video player section that doesn't use SafeArea
            SizedBox(
              height: screenHeight * 0.06,
            ),
            SizedBox(
              height: screenHeight * 0.3,
              width: screenWidth,
              child: NewScreenPlayer(videoUrl: _currentVideoUrl, isLiveStream: _isLiveStream),
            ),
            // Content section that uses SafeArea
            Expanded(
              child: SafeArea(
                top: false, // Important! Don't add safe area padding at the top
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
                              width: screenWidth * 0.72,
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
                            if (_isLiveStream)
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: verticalSpacing * 0.5, horizontal: verticalSpacing * 0.1),
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
                            const Text("|", style: TextStyle(color: Colors.white)),
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
                              borderRadius: BorderRadius.circular(screenWidth * 0.1),
                            ),
                            child: Center(
                              child: Text(
                                'Visit Website',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: buttonFontSize,
                                  fontWeight: FontWeight.bold,
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
                        SuggestedVideoCard(onVideoTap: _playVideo),
                        SizedBox(height: verticalSpacing * 2),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}