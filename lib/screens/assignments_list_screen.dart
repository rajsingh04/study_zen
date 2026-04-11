import 'package:flutter/material.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
import 'package:intl/intl.dart';
import 'package:study_zen/models/assignment_model.dart';
import 'package:study_zen/screens/assignment_detail_screen.dart';
import 'package:study_zen/services/assignment_service.dart';
import 'package:study_zen/utils/theme.dart';

class AssignmentsListScreen extends StatefulWidget {
  final int subjectId;
  final String subjectName;
  final bool isTeacher;

  const AssignmentsListScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.isTeacher,
  });

  @override
  State<AssignmentsListScreen> createState() => _AssignmentsListScreenState();
}

class _AssignmentsListScreenState extends State<AssignmentsListScreen> {
  final AssignmentService _assignmentService = const AssignmentService();

  bool _loading = true;
  List<AssignmentModel> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _assignmentService.fetchAssignments(subjectId: widget.subjectId);
      list.sort((a, b) {
        final aa = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bb.compareTo(aa);
      });
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      IconSnackBar.show(
        context,
        snackBarType: SnackBarType.alert,
        label: 'Failed to load assignments',
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text('Assignments · ${widget.subjectName}'),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: headerGradient)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 160),
                        Center(child: Text('No assignments yet')),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final a = _items[i];
                        final due = a.dueDate != null
                            ? DateFormat.yMMMd().add_jm().format(a.dueDate!.toLocal())
                            : 'No due date';
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
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
                              backgroundColor: AppColors.primary.withOpacity(0.08),
                              child: const Icon(Icons.assignment_outlined, color: AppColors.primary),
                            ),
                            title: Text(a.title),
                            subtitle: Text(due),
                            onTap: () async {
                              final changed = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AssignmentDetailScreen(
                                    subjectName: widget.subjectName,
                                    assignment: a,
                                    isTeacher: widget.isTeacher,
                                  ),
                                ),
                              );
                              if (changed == true) {
                                await _load();
                              }
                            },
                            trailing: widget.isTeacher
                                ? PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        final changed = await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => AssignmentDetailScreen(
                                              subjectName: widget.subjectName,
                                              assignment: a,
                                              isTeacher: true,
                                              openEditOnOpen: true,
                                            ),
                                          ),
                                        );
                                        if (changed == true) {
                                          await _load();
                                        }
                                        return;
                                      }

                                      if (value == 'delete') {
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Delete Assignment'),
                                            content: const Text('Are you sure you want to delete this assignment?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(ctx).pop(false),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.of(ctx).pop(true),
                                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirmed != true) return;

                                        final res = await _assignmentService.deleteAssignment(a.id);
                                        if (!mounted) return;
                                        if (res['success'] == true) {
                                          await _load();
                                          IconSnackBar.show(
                                            context,
                                            snackBarType: SnackBarType.success,
                                            label: 'Assignment deleted',
                                            backgroundColor: Colors.green,
                                          );
                                        } else {
                                          IconSnackBar.show(
                                            context,
                                            snackBarType: SnackBarType.alert,
                                            label: res['error']?.toString() ?? 'Failed to delete',
                                            backgroundColor: Colors.red,
                                          );
                                        }
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                                    ],
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
