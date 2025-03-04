import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Mercy TV',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
        backgroundColor: Colors.black, 
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'About Mercy TV',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Mercy TV is an Indian Islamic and Educational Satellite Channel. It is trying to create a positive change in the Indian Society by connecting people to their Creator. Mercy TV is trying to create harmony, understanding and tolerance among people from different faiths.',
            style: TextStyle(fontSize: 16),),
            SizedBox(height: 16),
            Text(
              'Satellite Frequency:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Intelsat 17 at 66.0°E Downlink Freq 3894MHz Symbol Rate 13840 ksps Polarization-HFEC 5/6 Modulation -8psk DVB S2 MPEG4',
            style: TextStyle(fontSize: 16),),
            SizedBox(height: 16),
            Text(
              'OUR GOAL',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Mercy TV is trying to create a positive change in the Indian Society by connecting people to their morals. Mercy TV is trying to establish harmony, understanding, and tolerance among people belonging to different faiths. Mercy TV has quality programs for the entire Family – Women, Children, Teens, Elderly. Mercy TV has motivational and knowledgeable programs for its viewers which altogether focus keenly on religious education and empowering people towards becoming dominant in fields like sports, science, technology etc.',
            style: TextStyle(fontSize: 16),),
            SizedBox(height: 16),
            Text(
              'Our Network',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Mercy TV is FTA free to air channel, telecasting on Jio TV+ 1099, Den network -800, City digital – 549/633, Asia Net – 190, NXT digital – 074, KCL – 744, VK digital – 134, SDV network – 535, SSC network – 368, U Digital -596, etc. Mercy TV has reached 200 million people all over India, functioning since 3 years.',
            style: TextStyle(fontSize: 16),),
          ],
        ),
      ),
    );
  }
}
