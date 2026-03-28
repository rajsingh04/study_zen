import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_zen/bloc/userbloc/user_bloc.dart';
import 'package:study_zen/bloc/userbloc/user_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF6F9),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Header (Logo + Profile)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.menu_book, color: Color(0xFF67B0A7), size: 30),
                        const SizedBox(width: 8),
                        Row(
                          children: const [
                            Text(
                              'Study',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3B5B72),
                              ),
                            ),
                            Text(
                              'Zen',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD49A36),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const CircleAvatar(
                      backgroundColor: Colors.grey,
                      radius: 20,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                
                // Welcome Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF669DAB), Color(0xFF81C39A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BlocBuilder<UserBloc, UserState>(
                        builder: (context, state) {
                          String username = 'Guest';
                          if (state is UserLoaded) {
                            username = state.user.username;
                          }
                          return Text(
                            'Welcome Back, $username!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Welcome to your Learning !',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                // Page indicator (dots)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 6,
                      width: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7CA1AC),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      height: 6,
                      width: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      height: 6,
                      width: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // My Courses Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Courses',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1C1C),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'See All',
                        style: TextStyle(color: Color(0xFF67B0A7), fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                
                // Horizontal list of courses
                SizedBox(
                  height: 180,
                  child: ListView(
                    clipBehavior: Clip.none, // to allow shadows
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildCourseCard('Software Engineering', '30 Tasks', Icons.computer, const [Color(0xFF7CB8AA), Color(0xFF9CC9B0)]),
                      const SizedBox(width: 15),
                      _buildCourseCard('Design & Analysis of Algorithms', '25 Tasks', Icons.account_tree, const [Color(0xFF619CAB), Color(0xFF8DCBA1)]),
                      const SizedBox(width: 15),
                      _buildCourseCard('Operation Research', '18 Tasks', Icons.analytics, const [Color(0xFF6A9DB9), Color(0xFF90C2C3)]),
                      const SizedBox(width: 15),
                      _buildCourseCard('Cryptography & Network Security', '40 Tasks', Icons.security, const [Color(0xFF8DA3A6), Color(0xFFB5C3C6)]),
                      const SizedBox(width: 15),
                      _buildCourseCard('Principal Management & Economics', '12 Tasks', Icons.business, const [Color(0xFF7D9C98), Color(0xFF9EBAB6)]),
                    ],
                  ),
                ),
                
                const SizedBox(height: 25),

                // Daily Tasks Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Daily Tasks',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1C1C),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'See All',
                        style: TextStyle(color: Color(0xFF67B0A7), fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                
                // Tasks List
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildTaskItem('Assignment', '45 minutes', true),
                      const Padding(
                        padding: EdgeInsets.only(left: 60, right: 20),
                        child: Divider(height: 1, color: Color(0xFFF0F0F0)),
                      ),
                      _buildTaskItem('PYQ\'s', '60 minutes', false),
                      const Padding(
                        padding: EdgeInsets.only(left: 60, right: 20),
                        child: Divider(height: 1, color: Color(0xFFF0F0F0)),
                      ),
                      _buildTaskItem('Question Bank', '30 minutes', false),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ]
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF67B0A7),
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
            items: const [
              BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 5), child: Icon(Icons.home, size: 28)), label: 'Home'),
              BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 5), child: Icon(Icons.menu_book_outlined, size: 28)), label: 'Courses'),
              BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 5), child: Icon(Icons.check_box_outlined, size: 28)), label: 'Tasks'),
              BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 5), child: Icon(Icons.person_outline, size: 28)), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(String title, String subtitle, IconData icon, List<Color> gradientColors) {
    return Container(
      width: 130, // Making cards slightly wider
      margin: const EdgeInsets.only(bottom: 10), // For shadow
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 80,
            width: double.infinity,
            margin: const EdgeInsets.all(8), // Inward margin
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 40),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1C1C1C)),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Course cards',
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(String title, String duration, bool isCompleted) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: isCompleted ? const Color(0xFF6CA89D) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isCompleted ? const Color(0xFF6CA89D) : Colors.grey.shade400,
            width: 2,
          ),
        ),
        child: isCompleted
            ? const Icon(Icons.check, size: 18, color: Colors.white)
            : null,
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF2C2C2C)),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          duration,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ),
      trailing: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
      ),
    );
  }
}
