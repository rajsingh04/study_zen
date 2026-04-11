import 'package:flutter/material.dart';
import 'package:study_zen/utils/theme.dart';

class QuizzesDetailScreen extends StatelessWidget {
  final String subjectName;
  final String title;

  const QuizzesDetailScreen({
    super.key,
    required this.subjectName,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(title),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: headerGradient)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
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
          child: Text('Quiz detail screen for $subjectName'),
        ),
      ),
    );
  }
}
