import 'package:flutter/material.dart';
import 'package:mercy_tv_app/Colors/custom_color.dart';
import 'package:mercy_tv_app/Screens/about_screen.dart';
import 'package:mercy_tv_app/Screens/profile_page.dart';

class Appbar extends StatelessWidget{
  const Appbar({super.key});

  @override
  Widget build(BuildContext context) {
   return Scaffold(
    appBar: AppBar(
        title: const Text(
          'Mercy TV',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          overflow: TextOverflow.clip,
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        automaticallyImplyLeading: true,
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.black, // Set background color to black
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: CustomColors.primary,
                ),
                child: Text(
                  'Mercy TV',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.home,
                  color: Colors.white,
                ),
                title: const Text(
                  'Home',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.white),
                title: const Text(
                  'Profile',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfilePage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.dataset, color: Colors.white),
                title: const Text(
                  'About Us',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AboutScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
   );
  }
}