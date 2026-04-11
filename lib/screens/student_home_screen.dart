import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
import 'package:study_zen/bloc/userbloc/user_bloc.dart';
import 'package:study_zen/bloc/userbloc/user_state.dart';
import 'package:study_zen/models/subject_model.dart';
import 'package:study_zen/screens/profile_screen.dart';
import 'package:study_zen/screens/subject_detail_screen.dart';
import 'package:study_zen/services/subject_service.dart';
import 'package:study_zen/utils/theme.dart';
import 'package:study_zen/utils/widget_style.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _selectedIndex = 0;
  final SubjectService _subjectService = const SubjectService();
  Future<List<SubjectModel>>? _subjectsFuture;

  @override
  void initState() {
    super.initState();
    _subjectsFuture = _subjectService.fetchSubjects();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return _CoursesTab(
          future: _subjectsFuture,
          onRefresh: () {
            setState(() {
              _subjectsFuture = _subjectService.fetchSubjects();
            });
          },
        );
      case 2:
        return _buildHomeContent(); // placeholder Tasks view for now
      case 3:
      default:
        return const ProfileScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: _buildPage(),
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: _openJoinCourseDialog,
              backgroundColor: const Color(0xFF67B0A7),
              icon: const Icon(Icons.link, color: Colors.white),
              label: const Text(
                'Join Course',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
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
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
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

  Widget _buildHomeContent() {
    return SingleChildScrollView(
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
                    Image.asset('assets/images/logo.png', height: 40, width: 40),
                    const SizedBox(width: 8),
                        ShaderMask(
                          shaderCallback: (bounds) => headerGradient.createShader(bounds),
                      child: const Text(
                        'Study Zen',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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
                gradient: headerGradient,
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
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },
                  child: const Text(
                    'See All',
                    style: TextStyle(color: Color(0xFF67B0A7), fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Horizontal list of enrolled courses
            SizedBox(
              height: 180,
              child: FutureBuilder<List<SubjectModel>>(
                future: _subjectsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Failed to load courses'));
                  }
                  final subjects = snapshot.data ?? [];
                  if (subjects.isEmpty) {
                    return const Center(
                      child: Text('No courses yet. Use "Join Course" to enroll.'),
                    );
                  }
                  final recentSubjects = subjects.length <= 3 ? subjects : subjects.sublist(0, 3);
                  return ListView.separated(
                    clipBehavior: Clip.none,
                    scrollDirection: Axis.horizontal,
                    itemCount: recentSubjects.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 15),
                    itemBuilder: (context, index) {
                      final subject = recentSubjects[index];
                      return GestureDetector(
                        onTap: () async {
                          final refreshed = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => SubjectDetailScreen(subject: subject),
                            ),
                          );
                          if (refreshed == true) {
                            // Refresh enrolled courses after unenrolling
                            // or any other change from details.
                            final state = context.findAncestorStateOfType<_StudentHomeScreenState>();
                            state?.setState(() {
                              state._subjectsFuture = state._subjectService.fetchSubjects();
                            });
                          }
                        },
                        child: courseCard(
                          subject.name,
                          '',
                          Icons.menu_book_outlined,
                          const [Color(0xFF7CB8AA), Color(0xFF9CC9B0)],
                          width: 150,
                        ),
                      );
                    },
                  );
                },
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
                  taskItem('Assignment', '45 minutes', true),
                  const Padding(
                    padding: EdgeInsets.only(left: 60, right: 20),
                    child: Divider(height: 1, color: Color(0xFFF0F0F0)),
                  ),
                  taskItem('PYQ\'s', '60 minutes', false),
                  const Padding(
                    padding: EdgeInsets.only(left: 60, right: 20),
                    child: Divider(height: 1, color: Color(0xFFF0F0F0)),
                  ),
                  taskItem('Question Bank', '30 minutes', false),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Future<void> _openJoinCourseDialog() async {
    final controller = TextEditingController();
    bool isJoining = false;
    String? errorText;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [AppColors.authBackgroundTop, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Join Course',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Paste the course link shared by your teacher to enroll.',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: 'Course link',
                        hintText: 'e.g. https://studyzen.app/join/2#3',
                        prefixIcon: const Icon(Icons.link),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        errorText: errorText,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: isJoining
                              ? null
                              : () async {
                          final input = controller.text.trim();
                          if (input.isEmpty) return;

                          // Expect links like /join/<teacherId>#<subjectId>
                          // and extract the subject id after '#'.
                          final hashMatch = RegExp(r'#(\d+)$').firstMatch(input);
                          final match = hashMatch ?? RegExp(r'(\d+)$').firstMatch(input);
                          if (match == null) {
                            setStateDialog(() {
                              errorText = 'Invalid link. Please check and try again.';
                            });
                            return;
                          }

                          final id = int.tryParse(match.group(1)!);
                          if (id == null) {
                            setStateDialog(() {
                              errorText = 'Invalid link. Please check and try again.';
                            });
                            return;
                          }

                          setStateDialog(() {
                            isJoining = true;
                          });

                          // If already enrolled in this course, show validation error and skip API call
                          try {
                            final current = await _subjectsFuture;
                            if (current != null && current.any((s) => s.id == id)) {
                              setStateDialog(() {
                                isJoining = false;
                                errorText = 'You are already enrolled in this course.';
                              });
                              return;
                            }
                          } catch (_) { 
                          }

                          final result = await _subjectService.enrollInSubject(id);
                          if (!mounted) return;

                          if (result['success'] == true) {
                            Navigator.of(ctx).pop();
                            setState(() {
                              _subjectsFuture = _subjectService.fetchSubjects();
                            });
                            final message = result['message']?.toString() ?? 'You joined the course';
                            IconSnackBar.show(
                              context,
                              snackBarType: SnackBarType.success,
                              label: message,
                              backgroundColor: Colors.green,
                            );
                          } else {
                            setStateDialog(() {
                              isJoining = false;
                            });
                            final error = result['error']?.toString() ?? 'Failed to join course';
                            IconSnackBar.show(
                              context,
                              snackBarType: SnackBarType.alert,
                              label: error,
                              backgroundColor: Colors.red,
                            );
                          }
                        },
                          child: isJoining
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Join',
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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

class _CoursesTab extends StatelessWidget {
  final Future<List<SubjectModel>>? future;
  final VoidCallback onRefresh;

  const _CoursesTab({super.key, required this.future, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SubjectModel>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Failed to load courses'));
        }
        final subjects = snapshot.data ?? [];
        if (subjects.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                Icon(Icons.menu_book_outlined, size: 64, color: AppColors.primary),
                SizedBox(height: 16),
                Text(
                  'No courses yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Ask your teacher to share a course link, then use the "Join Course" button below to enroll.',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Your Courses',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1C1C),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'All the classes you are currently enrolled in.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _CourseStatCard(
                        icon: Icons.menu_book_outlined,
                        label: 'Enrolled',
                        value: subjects.length.toString(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CourseStatCard(
                        icon: Icons.check_circle_outline,
                        label: 'Completed',
                        value: subjects.where((s) => s.isCompleted).length.toString(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Enrolled Courses',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1C1C),
                  ),
                ),
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: subjects.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final subject = subjects[index];
                    final owner = subject.ownerName;
                    final description = subject.description?.isNotEmpty == true
                        ? subject.description!
                        : 'Tap to view details';
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              AppColors.authBackgroundTop.withOpacity(0.06),
                              Colors.white,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.secondary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(Icons.book, color: Colors.white, size: 20),
                          ),
                          title: Text(
                            subject.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Color(0xFF1C1C1C),
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (owner != null && owner.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Created by $owner',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                            ],
                          ),
                          trailing: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.9),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              subject.isCompleted ? Icons.check_circle : Icons.chevron_right,
                              size: 18,
                              color: subject.isCompleted ? Colors.green : AppColors.primary,
                            ),
                          ),
                          onTap: () async {
                            final refreshed = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => SubjectDetailScreen(subject: subject),
                              ),
                            );
                            if (refreshed == true) {
                              onRefresh();
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CourseStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CourseStatCard({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


