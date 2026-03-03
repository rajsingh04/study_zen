import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_zen/bloc/userbloc/user_bloc.dart';
import 'package:study_zen/bloc/userbloc/user_state.dart';
import 'package:study_zen/utils/widget_style.dart';
import '../bloc/userbloc/user_event.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'package:study_zen/services/user_service.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  var isLoading = false;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  void _checkAutoLogin() async {
    final user = await _userService.getStoredUser();
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<UserBloc, UserState>(
        listener: (context, state) {

          if (state is UserLoaded) {
            isLoading = false;
            IconSnackBar.show(
              context,
              snackBarType: SnackBarType.success,
              label: 'Login successful',
              backgroundColor: Colors.green,
            );
            // Replace current route with HomeScreen so user can't go back
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else if (state is UserError) {
            isLoading = false;
            IconSnackBar.show(
              context,
              snackBarType: SnackBarType.alert,
              label: state.message,
              backgroundColor: Colors.red,
            );
          } else if (state is UserLoading) {
            isLoading = true;
          }
        },
        child: Container(
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
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/icon_with_title.jpeg',
                      height: 200,
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'Welcome back to StudyZen.',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: 350,
                      child: inputField(
                        'Email',
                        Icons.email_outlined,
                        controller: emailController,
                      ),
                    ),
                    const SizedBox(height: 30),
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
                    SizedBox(
                      width: 350,
                      child: styledButton("Login", () {
                        if (!_formKey.currentState!.validate()) {
                          return;
                        }
                        context.read<UserBloc>().add(OnLoginEvent(
                          email: emailController.text,
                          password: passwordController.text,
                        ));
                      }, isLoading),
                    ),
                    const SizedBox(height: 30),
                    InkWell(
                      onTap: () {},
                      child: Text(
                        "Forgot Password?",
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF6B90AD),
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 60),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: TextStyle(fontSize: 18, color: Colors.black54),
                        ),
                        const SizedBox(width: 5),
                        InkWell(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: Text(
                            "Sign Up",
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(0xFF6B90AD),
                              fontWeight: FontWeight.w500,
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
        ),
      ),
    );
  }
}
