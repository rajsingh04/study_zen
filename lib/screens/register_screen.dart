import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_zen/bloc/userbloc/user_bloc.dart';
import 'package:study_zen/bloc/userbloc/user_event.dart';
import 'package:study_zen/bloc/userbloc/user_state.dart';
import 'package:study_zen/utils/widget_style.dart';
import 'login_screen.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController accountTypeController = TextEditingController();
  List<String> accountTypes = ['Student', 'Teacher'];
  String? selectedAccountType;
  final _formKey = GlobalKey<FormState>();
  var isLoading = false;

  @override
  Widget build(BuildContext context) {
    final userbloc = context.read<UserBloc>();
    return Scaffold(
      body: BlocListener<UserBloc, UserState>(
        listener: (context, state) {
          if (state is UserLoaded) {
            isLoading = false;
            IconSnackBar.show(
              context,
              snackBarType: SnackBarType.success,
              label: 'Registration successful',
              backgroundColor: Colors.green,
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FBFB), Color(0xFFE2F1ED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
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

                const SizedBox(height: 30),

                // Full Name Field
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: inputField(
                    'Username',
                    Icons.person_outline,
                    controller: nameController,
                  ),
                ),

                const SizedBox(height: 30),

                // Email Field
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: inputField(
                    'Email',
                    Icons.email_outlined,
                    controller: emailController,
                  ),
                ),

                const SizedBox(height: 30),

                // Password Field
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: inputField(
                    'Password',
                    Icons.lock_outline,
                    isPassword: true,
                    controller: passwordController,
                  ),
                ),

                const SizedBox(height: 30),

              FormField<String>(
                validator: (v) => (selectedAccountType == null || selectedAccountType!.isEmpty) ? 'Please select account type' : null,
                builder: (state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownMenu(
                        controller: accountTypeController,
                        leadingIcon: Icon(
                          Icons.account_circle_outlined,
                          color: Colors.grey,
                        ),
                        menuStyle: MenuStyle(
                          backgroundColor: WidgetStateProperty.all(Colors.white),
                          elevation: WidgetStateProperty.all(4),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        inputDecorationTheme: InputDecorationTheme(
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.grey.shade500,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.red.shade300,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        dropdownMenuEntries: accountTypes
                            .map(
                              (type) => DropdownMenuEntry(
                                value: type.toUpperCase(),
                                label: type,
                              ),
                            )
                            .toList(),
                        onSelected: (value) {
                          setState(() {
                            selectedAccountType = value;
                          });
                          state.didChange(value);
                        },
                        hintText: "Select Account Type",
                        width: MediaQuery.of(context).size.width * 0.8,
                      ),
                      if (state.hasError)
                        Padding(
                          padding: const EdgeInsets.only(left: 12.0, top: 6.0),
                          child: Text(state.errorText ?? '', style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                        ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 30),
                // Register Button
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: styledButton("Register", () {
                    if (!(_formKey.currentState?.validate() ?? false)) {
                      return;
                    }
                    userbloc.add(OnRegisterEvent(
                      username: nameController.text.trim(),
                      email: emailController.text.trim(),
                      password: passwordController.text,
                      accountType: selectedAccountType ?? '',
                    ));
                  },isLoading),
                ),

                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account?",
                      style: TextStyle(fontSize: 18, color: Colors.black54),
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
                          fontSize: 18,
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
      ),
    ),
    );
  }
}
