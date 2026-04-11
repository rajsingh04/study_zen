import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
import 'package:study_zen/bloc/userbloc/user_bloc.dart';
import 'package:study_zen/bloc/userbloc/user_state.dart';
import 'package:study_zen/models/subject_model.dart';
import 'package:study_zen/services/subject_service.dart';
import 'package:study_zen/utils/theme.dart';
import 'package:study_zen/utils/widget_style.dart';

class SubjectDetailScreen extends StatefulWidget {
  final SubjectModel subject;

  const SubjectDetailScreen({super.key, required this.subject});

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  final SubjectService _subjectService = const SubjectService();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isEditing = false;
  bool _fabExpanded = false;
  bool _hasUpdated = false;
  String? _ownerName;
  bool _isCompleted = false;

  // Last saved values, used to revert when cancelling edits
  late String _savedName;
  late String _savedDescription;
  late bool _savedIsCompleted;

  @override
  void initState() {
    super.initState();
    _savedName = widget.subject.name;
    _savedDescription = widget.subject.description ?? '';
    _savedIsCompleted = widget.subject.isCompleted;

    _nameController = TextEditingController(text: _savedName);
    _descriptionController = TextEditingController(text: _savedDescription);
    // Owner name is provided by the subjects list API via
    // SubjectModel.ownerName; no extra detail call needed.
    _ownerName = widget.subject.ownerName;
    _isCompleted = widget.subject.isCompleted;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    if (name.isEmpty) {
      IconSnackBar.show(
        context,
        snackBarType: SnackBarType.alert,
        label: 'Subject name cannot be empty',
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final result = await _subjectService.updateSubject(
      widget.subject.id,
      name,
      description,
      isCompleted: _isCompleted,
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (result['success'] == true) {
      // Update local controllers so read-only view shows latest values
      _nameController.text = name;
      _descriptionController.text = description;
      final updated = result['subject'];
      if (updated is SubjectModel) {
        _isCompleted = updated.isCompleted;
      }
      _savedName = _nameController.text;
      _savedDescription = _descriptionController.text;
      _savedIsCompleted = _isCompleted;
      _hasUpdated = true;
      IconSnackBar.show(
        context,
        snackBarType: SnackBarType.success,
        label: 'Subject updated',
        backgroundColor: Colors.green,
      );
      setState(() {
        _isEditing = false;
      });
      // Stay on details page; list will refresh when user navigates back.
    } else {
      final error = result['error']?.toString() ?? 'Failed to update subject';
      IconSnackBar.show(
        context,
        snackBarType: SnackBarType.alert,
        label: error,
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _confirmDelete() async {
    if (_isDeleting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject'),
        content: const Text('Are you sure you want to delete this subject? This action cannot be undone.'),
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

    setState(() {
      _isDeleting = true;
    });

    final result = await _subjectService.deleteSubject(widget.subject.id);

    if (!mounted) return;

    setState(() {
      _isDeleting = false;
    });

    if (result['success'] == true) {
      IconSnackBar.show(
        context,
        snackBarType: SnackBarType.success,
        label: 'Subject deleted',
        backgroundColor: Colors.green,
      );
      Navigator.of(context).pop(true); // tell caller to refresh list
    } else {
      final error = result['error']?.toString() ?? 'Failed to delete subject';
      IconSnackBar.show(
        context,
        snackBarType: SnackBarType.alert,
        label: error,
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserBloc>().state;
    final bool isTeacher =
      userState is UserLoaded && userState.user.accountType.toUpperCase() == 'TEACHER';
    final bool isCompleted = _isCompleted;

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_hasUpdated);
        return false;
      },
      child: Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Subject Details'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: headerGradient,
          ),
        ),
        actions: [
          if (isTeacher)
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit_outlined),
              onPressed: (_isSaving || _isDeleting)
                  ? null
                  : () {
                      setState(() {
                        if (_isEditing) {
                          // Cancel edits: revert to last saved values
                          _nameController.text = _savedName;
                          _descriptionController.text = _savedDescription;
                          _isCompleted = _savedIsCompleted;
                          _isEditing = false;
                        } else {
                          _isEditing = true;
                        }
                      });
                    },
            ),
          if (!isCompleted)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: _isDeleting ? null : _shareSubject,
            ),
          if (isTeacher)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _isDeleting ? null : _confirmDelete,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: headerGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 54,
                          width: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.18),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _isEditing
                                  ? TextField(
                                      controller: _nameController,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Subject Name',
                                        labelStyle: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.white.withOpacity(0.6),
                                          ),
                                        ),
                                        focusedBorder: const UnderlineInputBorder(
                                          borderSide: BorderSide(color: Colors.white),
                                        ),
                                      ),
                                    )
                                  : Text(
                                      _nameController.text,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  _buildInfoChip(Icons.bookmark_outline, 'Subject'),
                                  _buildInfoChip(
                                    isCompleted
                                        ? Icons.check_circle_outline
                                        : Icons.radio_button_unchecked,
                                    isCompleted ? 'Completed' : 'Active',
                                  ),
                                  if (_ownerName != null && _ownerName!.isNotEmpty)
                                    _buildInfoChip(
                                      Icons.person_outline,
                                      'Created by $_ownerName',
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _isEditing
                      ? TextField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            _descriptionController.text.isEmpty
                                ? 'No description added yet.'
                                : _descriptionController.text,
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ),
                  const SizedBox(height: 24),
                  if (isTeacher && _isEditing)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        children: [
                          Icon(
                            isCompleted ? Icons.check_circle_outline : Icons.timelapse,
                            size: 18,
                            color: isCompleted ? Colors.green : AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Course status',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1C1C1C),
                            ),
                          ),
                          const Spacer(),
                          Switch(
                            value: isCompleted,
                            onChanged: (value) {
                              setState(() {
                                _isCompleted = value;
                              });
                            },
                            activeColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  if (isTeacher && _isEditing)
                    const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.insert_drive_file_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Materials',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
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
                        backgroundColor: AppColors.primary.withOpacity(0.08),
                        child: Icon(
                          Icons.insert_drive_file_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      title: const Text('No materials yet'),
                      subtitle: const Text('Use "Add Material" to attach resources.'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Assignments',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
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
                        backgroundColor: AppColors.primary.withOpacity(0.08),
                        child: Icon(
                          Icons.assignment_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      title: const Text('No assignments yet'),
                      subtitle: const Text('Use "Add Assignment" to create one.'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(
                        Icons.quiz_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Quizzes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
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
                        backgroundColor: AppColors.primary.withOpacity(0.08),
                        child: Icon(
                          Icons.quiz_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      title: const Text('No quizzes yet'),
                      subtitle: const Text('Use "Add Quiz" to create one.'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isTeacher && _isEditing)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: styledButton(
                  _isSaving ? 'Saving...' : 'Save Changes',
                  () {
                    if (_isSaving) return;
                    _saveChanges();
                  },
                  _isSaving,
                ),
              ),
            ),
          if (!isTeacher)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: styledButton(
                  'Unenroll from Course',
                  () {
                    if (_isDeleting) return;
                    _confirmUnenroll();
                  },
                  _isDeleting,
                ),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation:
          isTeacher && !isCompleted ? FloatingActionButtonLocation.endFloat : null,
        floatingActionButton: isTeacher && !isCompleted
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_fabExpanded) ...[
                  _buildActionFab(
                    heroTag: 'material-${widget.subject.id}',
                    icon: Icons.insert_drive_file_outlined,
                    label: 'Add Material',
                    onTap: () {
                      IconSnackBar.show(
                        context,
                        snackBarType: SnackBarType.alert,
                        label: 'Add Material coming soon',
                        backgroundColor: Colors.blueGrey,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildActionFab(
                    heroTag: 'assignment-${widget.subject.id}',
                    icon: Icons.assignment_outlined,
                    label: 'Add Assignment',
                    onTap: () {
                      IconSnackBar.show(
                        context,
                        snackBarType: SnackBarType.alert,
                        label: 'Add Assignment coming soon',
                        backgroundColor: Colors.blueGrey,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildActionFab(
                    heroTag: 'quiz-${widget.subject.id}',
                    icon: Icons.quiz_outlined,
                    label: 'Add Quiz',
                    onTap: () {
                      IconSnackBar.show(
                        context,
                        snackBarType: SnackBarType.alert,
                        label: 'Add Quiz coming soon',
                        backgroundColor: Colors.blueGrey,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                FloatingActionButton(
                  heroTag: 'toggle-fab-${widget.subject.id}',
                  backgroundColor: AppColors.primary,
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  onPressed: () {
                    setState(() {
                      _fabExpanded = !_fabExpanded;
                    });
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, anim) => RotationTransition(
                      turns: Tween<double>(begin: 0.8, end: 1).animate(anim),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: Icon(
                      _fabExpanded ? Icons.close : Icons.add,
                      key: ValueKey<bool>(_fabExpanded),
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            )
          : null,
    ),
    );
  }

  Future<void> _shareSubject() async {
    // Generate unique link using teacher (owner) id and subject id:
    // https://studyzen.app/join/<teacherId>#<subjectId>
    final teacherId = widget.subject.ownerId;
    final link = 'https://studyzen.app/join/$teacherId#${widget.subject.id}';
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;

    IconSnackBar.show(
      context,
      snackBarType: SnackBarType.success,
      label: 'Share link copied to clipboard',
      backgroundColor: Colors.green,
    );
  }

  Future<void> _confirmUnenroll() async {
    if (_isDeleting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Course'),
        content: const Text('Are you sure you want to unenroll from this course?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Unenroll', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    final result = await _subjectService.unenrollFromSubject(widget.subject.id);

    if (!mounted) return;

    setState(() {
      _isDeleting = false;
    });

    if (result['success'] == true) {
      final message = result['message']?.toString() ?? 'You have been unenrolled from this course';
      IconSnackBar.show(
        context,
        snackBarType: SnackBarType.success,
        label: message,
        backgroundColor: Colors.green,
      );
      Navigator.of(context).pop(true);
    } else {
      final error = result['error']?.toString() ?? 'Failed to unenroll from course';
      IconSnackBar.show(
        context,
        snackBarType: SnackBarType.alert,
        label: error,
        backgroundColor: Colors.red,
      );
    }
  }

  Widget _buildActionFab({
    required String heroTag,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return FloatingActionButton.extended(
      heroTag: heroTag,
      backgroundColor: AppColors.primary,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      onPressed: onTap,
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
