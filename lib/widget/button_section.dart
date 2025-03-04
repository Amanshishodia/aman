import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ButtonSection extends StatelessWidget {
  const ButtonSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                'assets/images/logo.png',
                height: 36,
                width: 36,
              ),
            ),
            const SizedBox(width: 15),
            const Text(
              'Mercy TV',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Mulish-Bold',
              ),
            ),
          ],
        ),
        const Spacer(),
        Visibility(
          visible: false, // Hides the share button
          child: GestureDetector(
            onTap: () {
              final String videoUrl = Platform.isIOS
                  ? 'https://mercytv.tv/' // iOS link
                  : 'https://play.google.com/store/apps/details?id=com.mercyott.app'; // Android link
              
              Share.share('Check out this Link: $videoUrl', subject: 'App Link');
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.share_outlined, color: Colors.white, size: 26),
                SizedBox(height: 4),
                Text(
                  'Share',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Mulish-Medium',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
