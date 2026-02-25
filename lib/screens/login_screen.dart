import 'package:flutter/material.dart';
import 'package:study_zen/utils/widget_style.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FBFB), Color(0xFFE2F1ED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/icon_with_title.jpeg', height: 200),
                const SizedBox(height: 30),
                Text(
                  'Welcome back to StudyZen.',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 60),
                SizedBox(
                  width: 350,
                  child: inputField('Email', Icons.email_outlined, controller: emailController),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: 350,
                  child: inputField('Password', Icons.lock_outline, isPassword: true, controller: passwordController),
                ),
                const SizedBox(height: 30),
                SizedBox(width: 350, child: styledButton("Login", () {})),
                const SizedBox(height: 30),
                InkWell(
                  onTap: () {},
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(fontSize: 18, color: Color(0xFF6B90AD), fontWeight: FontWeight.w400),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 60),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                  Text("Don't have an account?", style: TextStyle(fontSize: 18, color: Colors.black54)),
                  const SizedBox(width: 5),
                  InkWell(
                    onTap: () {},
                    child: Text(
                      "Sign Up",
                      style: TextStyle(fontSize: 18, color: Color(0xFF6B90AD), fontWeight: FontWeight.w500),
                    ),
                  )
                ],)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
