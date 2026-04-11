import 'package:flutter/material.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
import 'package:study_zen/models/user_model.dart';
import 'package:study_zen/services/subject_service.dart';
import 'package:study_zen/utils/theme.dart';

class EnrolledStudentsScreen extends StatelessWidget {
  final int subjectId;
  final String subjectName;

  const EnrolledStudentsScreen({super.key, required this.subjectId, required this.subjectName});

  @override
  Widget build(BuildContext context) {
    final subjectService = SubjectService();

    return Scaffold(
      appBar: AppBar(
        title: Text('Enrolled Students'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: headerGradient,
          ),
        ),
      ),
      backgroundColor: AppColors.scaffoldBackground,
      body: FutureBuilder<List<UserModel>>(
        future: subjectService.fetchEnrolledStudents(subjectId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final message = snapshot.error.toString();
            IconSnackBar.show(
              context,
              snackBarType: SnackBarType.alert,
              label: 'Failed to load students',
              backgroundColor: Colors.red,
            );
            return Center(child: Text('Failed to load students: $message'));
          }
          final students = snapshot.data ?? [];
          if (students.isEmpty) {
            return const Center(
              child: Text(
                'No students have enrolled in this class yet.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final student = students[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: Text(
                      student.username.isNotEmpty ? student.username[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    student.username,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    student.email,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                    tooltip: 'Unenroll student',
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Remove student'),
                          content: Text('Remove ${student.username} from this class?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed != true) return;

                      try {
                        final result = await subjectService.removeStudentFromSubject(subjectId, student.id);
                        if (result['success'] == true) {
                          IconSnackBar.show(
                            context,
                            snackBarType: SnackBarType.success,
                            label: result['message']?.toString() ?? 'Student removed',
                            backgroundColor: Colors.green,
                          );
                          // Refresh list after removal by popping and pushing again
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => EnrolledStudentsScreen(
                                subjectId: subjectId,
                                subjectName: subjectName,
                              ),
                            ),
                          );
                        } else {
                          IconSnackBar.show(
                            context,
                            snackBarType: SnackBarType.alert,
                            label: result['error']?.toString() ?? 'Failed to remove student',
                            backgroundColor: Colors.red,
                          );
                        }
                      } catch (e) {
                        IconSnackBar.show(
                          context,
                          snackBarType: SnackBarType.alert,
                          label: 'Failed to remove student',
                          backgroundColor: Colors.red,
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
