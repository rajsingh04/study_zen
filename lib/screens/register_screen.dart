import 'package:flutter/material.dart';
import 'package:study_zen/utils/widget_style.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FBFB), Color(0xFFE2F1ED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/icon_with_title.jpeg', height: 200),

                const SizedBox(height: 30),

                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 80),

                // Full Name Field
                SizedBox(
                  width: 350,
                  child: inputField(
                    'Full Name',
                    Icons.person_outline,
                    controller: nameController,
                  ),
                ),

                const SizedBox(height: 30),

                // Email Field
                SizedBox(
                  width: 350,
                  child: inputField(
                    'Email',
                    Icons.email_outlined,
                    controller: emailController,
                  ),
                ),

                const SizedBox(height: 30),

                // Password Field
                SizedBox(
                  width: 350,
                  child: inputField(
                    'Password',
                    Icons.lock_outline,
                    isPassword: true,
                    controller: passwordController,
                  ),
                ),

                const SizedBox(height: 30),

                // Register Button
                SizedBox(
                  width: 350,
                  child: styledButton("Register", () {
                    // Add registration logic here
                  }),
                ),

                const SizedBox(height: 40),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account?",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(width: 5),
                    InkWell(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B90AD),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
