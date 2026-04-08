import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
import 'package:study_zen/bloc/userbloc/user_bloc.dart';
import 'package:study_zen/bloc/userbloc/user_state.dart';
import 'package:study_zen/utils/widget_style.dart';
import 'package:study_zen/models/subject_model.dart';
import 'package:study_zen/services/subject_service.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  int _selectedIndex = 0;

  static const Color _accent = Color(0xFF67B0A7);

  final SubjectService _subjectService = const SubjectService();
  Future<List<SubjectModel>>? _subjectsFuture;

  final List<String> _titles = [
    'Home',
    'Subjects',
    'AI',
    'Profile',
  ];

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
        return const _HomeTab();
      case 1:
        return _SubjectsTab(future: _subjectsFuture);
      case 2:
        return const _AiTab();
      case 3:
      default:
        return const _ProfileTab();
    }
  }

  Future<void> _openAddSubjectDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFFE8F4F8), Color(0xFFFFFFFF)],
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
                      'Add New Subject',
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
                  'Create a subject for your classes. Students will be able to enroll in it.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Subject name',
                    prefixIcon: const Icon(Icons.book_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFB4CFD9)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFB4CFD9)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF67B0A7), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                    prefixIcon: const Icon(Icons.description_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFB4CFD9)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFB4CFD9)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF67B0A7), width: 1.5),
                    ),
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
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final description = descriptionController.text.trim();
                        if (name.isEmpty) return;
                        final result = await _subjectService.createSubject(name, description);
                        if (result['success'] == true) {
                          if (mounted) {
                            Navigator.of(ctx).pop();
                            setState(() {
                              _subjectsFuture = _subjectService.fetchSubjects();
                            }); // refresh subjects tab
                            IconSnackBar.show(
                              context,
                              snackBarType: SnackBarType.success,
                              label: 'Subject created successfully',
                              backgroundColor: Colors.green,
                            );
                          }
                        } else {
                          final error = result['error']?.toString() ?? 'Failed to create subject';
                          IconSnackBar.show(
                            context,
                            snackBarType: SnackBarType.alert,
                            label: error,
                            backgroundColor: Colors.red,
                          );
                        }
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Create'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 231, 244, 249),
      body: SafeArea(child: _buildPage()),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: _openAddSubjectDialog,
              backgroundColor: _accent,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: _accent,
        unselectedItemColor: Colors.black54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: 'Subjects'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy_outlined), label: 'AI'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF67B0A7);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Header: logo + Study Zen title + profile avatar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset('assets/images/logo.png', height: 40, width: 40),
                    const SizedBox(width: 8),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF67B0A7), Color(0xFF81C39A)],
                        stops: [0.3, 1.0],
                      ).createShader(bounds),
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
            const SizedBox(height: 16),

            // Welcome banner with gradient
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
                      String username = 'Teacher';
                      if (state is UserLoaded) username = state.user.username;
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
                    'Manage your classes and students',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats row
            Row(
              children: [
                Expanded(child: statCardWidget(Icons.view_module_outlined, 'Classes', '4', accent: accent, whiteBackground: true)),
                const SizedBox(width: 12),
                Expanded(child: statCardWidget(Icons.person_outline, 'Students', '128', accent: accent, whiteBackground: true)),
                const SizedBox(width: 12),
                Expanded(child: statCardWidget(Icons.assignment_outlined, 'Assignments', '6', accent: accent, whiteBackground: true)),
              ],
            ),

            const SizedBox(height: 18),

            // Upcoming lessons
            const Text('Upcoming Lessons', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  lessonTileWidget('Math: Algebra II', 'Today • 10:00 AM', gradientColors: [const Color(0xFF669DAB), const Color(0xFF81C39A)]),
                  lessonTileWidget('Physics: Mechanics', 'Today • 2:00 PM', gradientColors: [const Color(0xFF67B0A7), const Color(0xFF81C39A)]),
                  lessonTileWidget('Chemistry: Lab', 'Tomorrow • 11:00 AM', gradientColors: [const Color(0xFF6A9DB9), const Color(0xFF90C2C3)]),
                ],
              ),
            ),

            const SizedBox(height: 18),

            const Text('Recent Tests Added', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Column(
                children: [
                  ListTile(leading: Icon(Icons.quiz, color: accent), title: const Text('Algebra II — Chapter 5 Test'), subtitle: const Text('2 hours ago'),),
                  const Divider(height: 1),
                  ListTile(leading: Icon(Icons.article_outlined, color: accent), title: const Text('Physics Midterm (Draft)'), subtitle: const Text('Yesterday')),
                  const Divider(height: 1),
                  ListTile(leading: Icon(Icons.upload_file_outlined, color: accent), title: const Text('Chemistry Lab Quiz'), subtitle: const Text('3 days ago')),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Analytics summary
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Class Completion Rate', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: 0.72, color: accent, backgroundColor: accent.withOpacity(0.2)),
                    const SizedBox(height: 8),
                    const Text('72% of lessons completed this term', style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

Widget _lessonTile(String title, String subtitle) {
  return Container(
    width: 240,
    margin: const EdgeInsets.only(right: 12),
    child: Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    ),
  );
}

class _SubjectsTab extends StatelessWidget {
  final Future<List<SubjectModel>>? future;

  const _SubjectsTab({Key? key, required this.future}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: FutureBuilder<List<SubjectModel>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load subjects: ${snapshot.error}'));
          }
          final subjects = snapshot.data ?? [];
          if (subjects.isEmpty) {
            return const Center(child: Text('No subjects yet. Use + to add one.'));
          }
          return ListView.separated(
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF6B90AD),
                  child: Icon(Icons.book, color: Colors.white),
                ),
                title: Text(subject.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(subject.description?.isNotEmpty == true ? subject.description! : 'Tap to view details'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: navigate to subject detail page when implemented
                },
              );
            },
            separatorBuilder: (_, __) => const Divider(),
            itemCount: subjects.length,
          );
        },
      ),
    );
  }
}

class _AiTab extends StatelessWidget {
  const _AiTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.auto_awesome, size: 84, color: Color(0xFF6B90AD)),
            SizedBox(height: 20),
            Text('AI Assistant', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text('Ask the assistant to generate quizzes, summaries or suggestions for your class.', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            children: const [
              CircleAvatar(radius: 36, backgroundColor: Color(0xFF6B90AD), child: Icon(Icons.person, color: Colors.white, size: 36)),
              SizedBox(width: 16),
              Expanded(child: Text('Teacher Name', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Account', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ListTile(leading: const Icon(Icons.email_outlined), title: const Text('Email'), subtitle: const Text('teacher@example.com')),
          ListTile(leading: const Icon(Icons.settings_outlined), title: const Text('Settings')),
        ],
      ),
    );
  }
}