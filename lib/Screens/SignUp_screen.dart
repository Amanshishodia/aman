import 'package:flutter/material.dart';
import 'package:mercy_tv_app/Colors/custom_color.dart';
import 'package:mercy_tv_app/widget/Custom_textfield.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            'assets/images/sign_up.png',
            fit: BoxFit.cover,
          ),

          // Content Section
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.32),
                Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 26,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 24),

                // Container for Form Fields
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 24),
                  padding: EdgeInsets.all(16),
                  
                  child: Column(
                    children: [
                      CustomTextField(hintText: 'Email or phone'),
                      SizedBox(height: 15),

                      // First Name & Last Name Row
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(hintText: 'First name'),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: CustomTextField(hintText: 'Last Name'),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),

                      CustomTextField(
                        hintText: 'Password',
                        obscureText: true,
                      ),
                      SizedBox(height: 15),

                      CustomTextField(
                        hintText: 'Confirm Password',
                        obscureText: true,
                      ),
                      SizedBox(height: 30),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CustomColors.primary,
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: () {},
                        child: Text(
                          'Create Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                       SizedBox(height: 50),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account? "),
                          TextButton(
                            onPressed: () {
                              // Navigate to login page
                              print("Navigate to Login Screen");
                            },
                            child: const Text(
                              "Log in",
                              style: TextStyle(
                                color: Color(0xFF1D4D4F),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                       SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
