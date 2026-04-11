import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
import 'package:study_zen/bloc/userbloc/user_bloc.dart';
import 'package:study_zen/bloc/userbloc/user_state.dart';
import 'package:study_zen/models/user_model.dart';
import 'package:study_zen/services/user_service.dart';
import 'package:study_zen/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  bool _isLoggingOut = false;

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    setState(() {
      _isLoggingOut = true;
    });
    await _userService.logout();
    if (!mounted) return;

    IconSnackBar.show(
      context,
      snackBarType: SnackBarType.success,
      label: 'Logged out successfully',
      backgroundColor: Colors.green,
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF6F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BlocBuilder<UserBloc, UserState>(
                builder: (context, state) {
                  UserModel? user;
                  if (state is UserLoaded) {
                    user = state.user;
                  }
                  final String displayName = user?.username ?? 'Guest';
                  final String email = user?.email ?? 'Not available';
                  final String role = user?.accountType.toUpperCase() ?? 'UNKNOWN';

                  return Row(
                    children: [
                      const CircleAvatar(
                        radius: 36,
                        backgroundColor: Color(0xFF6B90AD),
                        child: Icon(Icons.person, color: Colors.white, size: 36),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: const TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Role: $role',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              const Text(
                'Account',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: const [
                    ListTile(
                      leading: Icon(Icons.email_outlined),
                      title: Text('Email'),
                      subtitle: Text('Shown above'),
                    ),
                    Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.lock_outline),
                      title: Text('Security'),
                      subtitle: Text('Manage your account security'),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC4C3E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isLoggingOut ? null : _handleLogout,
                  icon: _isLoggingOut
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.logout, color: Colors.white),
                  label: Text(
                    _isLoggingOut ? 'Logging out...' : 'Logout',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
