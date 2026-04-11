import 'package:flutter/material.dart';
import 'package:study_zen/screens/quizzes_detail_screen.dart';
import 'package:study_zen/utils/theme.dart';

class QuizzesListScreen extends StatelessWidget {
  final int subjectId;
  final String subjectName;

  const QuizzesListScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text('Quizzes · $subjectName'),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: headerGradient)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.secondary.withOpacity(0.10),
                child: const Icon(Icons.quiz_outlined, color: AppColors.secondary),
              ),
              title: const Text('No quizzes yet'),
              subtitle: const Text('Quizzes list screen is ready.'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => QuizzesDetailScreen(
                      subjectName: subjectName,
                      title: 'Quiz',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
