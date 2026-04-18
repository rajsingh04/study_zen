import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
import 'package:study_zen/bloc/userbloc/user_bloc.dart';
import 'package:study_zen/bloc/userbloc/user_state.dart';
import 'package:study_zen/models/subject_model.dart';
import 'package:study_zen/services/subject_service.dart';
import 'package:study_zen/services/assignment_service.dart';
import 'package:study_zen/models/assignment_model.dart';
import 'package:study_zen/services/material_service.dart';
import 'package:study_zen/models/material_model.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:study_zen/utils/theme.dart';
import 'package:study_zen/utils/widget_style.dart';
import 'package:study_zen/screens/enrolled_students_screen.dart';
import 'package:study_zen/screens/assignments_list_screen.dart';
import 'package:study_zen/screens/assignment_detail_screen.dart';
import 'package:study_zen/screens/materials_list_screen.dart';
import 'package:study_zen/screens/material_detail_screen.dart';

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
  final AssignmentService _assignmentService = const AssignmentService();
  List<AssignmentModel> _assignments = [];
  final MaterialService _materialService = const MaterialService();
  List<MaterialModel> _materials = [];
  bool _initialLoading = true;
  bool _loadingAssignments = true;
  bool _loadingMaterials = true;
  bool _initialAssignmentsDone = false;
  bool _initialMaterialsDone = false;
  bool _initialSubmissionStatusDone = false;

  final Map<int, bool> _submittingAssignment = <int, bool>{};
  final Set<int> _submittedAssignmentIds = <int>{};

  OverlayEntry? _toastEntry;
  Timer? _toastTimer;

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
    _loadAssignments();
    _loadMaterials();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _toastTimer = null;
    _toastEntry?.remove();
    _toastEntry = null;
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showOverlayToast({
    required String message,
    required Color backgroundColor,
    IconData icon = Icons.info_outline,
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!mounted) return;
    _toastTimer?.cancel();
    _toastTimer = null;
    _toastEntry?.remove();
    _toastEntry = null;

    final overlay = Overlay.of(context, rootOverlay: true);

    _toastEntry = OverlayEntry(
      builder: (ctx) {
        final top = MediaQuery.of(ctx).padding.top + 12;
        return Positioned(
          top: top,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.14),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_toastEntry!);
    _toastTimer = Timer(duration, () {
      _toastEntry?.remove();
      _toastEntry = null;
      _toastTimer = null;
    });
  }

  Future<void> _loadAssignments() async {
    final st = context.read<UserBloc>().state;
    final userLoaded = st is UserLoaded;
    final isTeacher = userLoaded && st.user.accountType.toUpperCase() == 'TEACHER';
    final gateSubmissionStatus = userLoaded && !isTeacher;

    if (mounted) {
      setState(() {
        _loadingAssignments = true;
      });
    }
    try {
      final list = await _assignmentService.fetchAssignments(subjectId: widget.subject.id);
      list.sort((a, b) {
        final aa = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bb.compareTo(aa);
      });
      if (!mounted) return;
      setState(() {
        _assignments = list;
        _loadingAssignments = false;
        if (!_initialAssignmentsDone) {
          _initialAssignmentsDone = true;
        }
        _initialLoading = !(_initialAssignmentsDone &&
            _initialMaterialsDone &&
            (!gateSubmissionStatus || _initialSubmissionStatusDone));
      });

      // For students: detect existing submissions for the visible top-3.
      // Keep the initial loader on until this completes so the button state is accurate.
      if (gateSubmissionStatus && !_initialSubmissionStatusDone) {
        await _primeSubmittedForVisibleAssignments();
        if (!mounted) return;
        setState(() {
          _initialSubmissionStatusDone = true;
          _initialLoading = !(_initialAssignmentsDone &&
              _initialMaterialsDone &&
              (!gateSubmissionStatus || _initialSubmissionStatusDone));
        });
      }
    } catch (e) {
      // ignore for now; assignments may be empty
      if (!mounted) return;
      setState(() {
        _loadingAssignments = false;
        if (!_initialAssignmentsDone) {
          _initialAssignmentsDone = true;
        }
        _initialLoading = !(_initialAssignmentsDone &&
            _initialMaterialsDone &&
            (!gateSubmissionStatus || _initialSubmissionStatusDone));
      });

      if (gateSubmissionStatus && !_initialSubmissionStatusDone) {
        await _primeSubmittedForVisibleAssignments();
        if (!mounted) return;
        setState(() {
          _initialSubmissionStatusDone = true;
          _initialLoading = !(_initialAssignmentsDone &&
              _initialMaterialsDone &&
              (!gateSubmissionStatus || _initialSubmissionStatusDone));
        });
      }
    }
  }

  Future<void> _primeSubmittedForVisibleAssignments() async {
    final ids = _assignments.take(3).map((a) => a.id).toList();
    if (ids.isEmpty) return;

    final futures = ids.map((id) async {
      if (_submittedAssignmentIds.contains(id)) return;
      try {
        final subs = await _assignmentService.fetchSubmissions(id);
        if (!mounted) return;
        if (subs.isNotEmpty) {
          setState(() => _submittedAssignmentIds.add(id));
        }
      } catch (_) {
        // ignore
      }
    });

    await Future.wait(futures);
  }

  Future<void> _loadMaterials() async {
    final st = context.read<UserBloc>().state;
    final userLoaded = st is UserLoaded;
    final isTeacher = userLoaded && st.user.accountType.toUpperCase() == 'TEACHER';
    final gateSubmissionStatus = userLoaded && !isTeacher;

    if (mounted) {
      setState(() {
        _loadingMaterials = true;
      });
    }
    try {
      final list = await _materialService.fetchMaterials(subjectId: widget.subject.id);
      list.sort((a, b) {
        final aa = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bb.compareTo(aa);
      });
      if (!mounted) return;
      setState(() {
        _materials = list;
        _loadingMaterials = false;
        if (!_initialMaterialsDone) {
          _initialMaterialsDone = true;
        }
        _initialLoading = !(_initialAssignmentsDone &&
            _initialMaterialsDone &&
            (!gateSubmissionStatus || _initialSubmissionStatusDone));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingMaterials = false;
        if (!_initialMaterialsDone) {
          _initialMaterialsDone = true;
        }
        _initialLoading = !(_initialAssignmentsDone &&
            _initialMaterialsDone &&
            (!gateSubmissionStatus || _initialSubmissionStatusDone));
      });
    }
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
      body: Stack(
        children: [
          Column(
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
                  const SizedBox(height: 12),
                  if (isTeacher)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.people_outline),
                        label: const Text('View enrolled students'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EnrolledStudentsScreen(
                                subjectId: widget.subject.id,
                                subjectName: _nameController.text,
                              ),
                            ),
                          );
                        },
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
                      const Spacer(),
                      TextButton(
                        onPressed: _materials.isEmpty
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => MaterialsListScreen(
                                      subjectId: widget.subject.id,
                                      subjectName: _nameController.text,
                                      isTeacher: isTeacher,
                                    ),
                                  ),
                                );
                              },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                        child: const Text('See all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_loadingMaterials && !_initialLoading)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          backgroundColor: AppColors.primary.withOpacity(0.12),
                        ),
                      ),
                    ),
                  if (_materials.isEmpty)
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
                        subtitle: Text(isTeacher
                            ? 'Use "Add Material" to upload one.'
                            : 'No materials uploaded yet.'),
                      ),
                    )
                  else
                    Column(
                      children: _materials.take(3).map((m) {
                        final created = m.createdAt != null
                            ? DateFormat.yMMMd().add_jm().format(m.createdAt!.toLocal())
                            : 'Material';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.06),
                              child: const Icon(Icons.insert_drive_file_outlined, color: AppColors.primary),
                            ),
                            title: Text(m.title),
                            subtitle: Text(created),
                            onTap: () async {
                              final changed = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => MaterialDetailScreen(
                                    subjectName: _nameController.text,
                                    material: m,
                                    isTeacher: isTeacher,
                                  ),
                                ),
                              );
                              if (changed == true) {
                                await _loadMaterials();
                              }
                            },
                            trailing: isTeacher
                                ? PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        final changed = await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => MaterialDetailScreen(
                                              subjectName: _nameController.text,
                                              material: m,
                                              isTeacher: true,
                                              openEditOnOpen: true,
                                            ),
                                          ),
                                        );
                                        if (changed == true) {
                                          await _loadMaterials();
                                        }
                                        return;
                                      }

                                      if (value == 'delete') {
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Delete Material'),
                                            content: const Text('Are you sure you want to delete this material?'),
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

                                        final res = await _materialService.deleteMaterial(m.id);
                                        if (!mounted) return;
                                        if (res['success'] == true) {
                                          await _loadMaterials();
                                          IconSnackBar.show(
                                            context,
                                            snackBarType: SnackBarType.success,
                                            label: 'Material deleted',
                                            backgroundColor: Colors.green,
                                          );
                                        } else {
                                          _showOverlayToast(
                                            message: res['error']?.toString() ?? 'Failed to delete',
                                            backgroundColor: Colors.red,
                                            icon: Icons.error_outline,
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
                      }).toList(),
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
                      const Spacer(),
                      TextButton(
                        onPressed: _assignments.isEmpty
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AssignmentsListScreen(
                                      subjectId: widget.subject.id,
                                      subjectName: _nameController.text,
                                      isTeacher: isTeacher,
                                    ),
                                  ),
                                );
                              },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                        child: const Text('See all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_loadingAssignments && !_initialLoading)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          backgroundColor: AppColors.primary.withOpacity(0.12),
                        ),
                      ),
                    ),
                  if (_assignments.isEmpty)
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
                    )
                  else
                    Column(
                      children: _assignments.take(3).map((a) {
                        final due = a.dueDate != null ? DateFormat.yMMMd().add_jm().format(a.dueDate!.toLocal()) : 'No due date';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.06),
                              child: Icon(Icons.assignment_outlined, color: AppColors.primary),
                            ),
                            title: Text(a.title),
                            subtitle: Text(due),
                            onTap: () async {
                              final changed = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AssignmentDetailScreen(
                                    subjectName: _nameController.text,
                                    assignment: a,
                                    isTeacher: isTeacher,
                                  ),
                                ),
                              );
                              if (changed == true) {
                                if (!isTeacher) {
                                  setState(() => _submittedAssignmentIds.add(a.id));
                                }
                                await _loadAssignments();
                              }
                            },
                            trailing: isTeacher
                                ? PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        final changed = await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => AssignmentDetailScreen(
                                              subjectName: _nameController.text,
                                              assignment: a,
                                              isTeacher: true,
                                              openEditOnOpen: true,
                                            ),
                                          ),
                                        );
                                        if (changed == true) {
                                          await _loadAssignments();
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
                                          await _loadAssignments();
                                          IconSnackBar.show(
                                            context,
                                            snackBarType: SnackBarType.success,
                                            label: 'Assignment deleted',
                                            backgroundColor: Colors.green,
                                          );
                                        } else {
                                          _showOverlayToast(
                                            message: res['error']?.toString() ?? 'Failed to delete',
                                            backgroundColor: Colors.red,
                                            icon: Icons.error_outline,
                                          );
                                        }
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                                    ],
                                  )
                                : ElevatedButton(
                                    onPressed: (_submittingAssignment[a.id] == true || _submittedAssignmentIds.contains(a.id))
                                        ? null
                                        : () async {
                                            // student submit
                                            final result = await _pickAndSubmit(a.id);
                                            if (result == true) {
                                              IconSnackBar.show(
                                                context,
                                                snackBarType: SnackBarType.success,
                                                label: 'Submitted',
                                                backgroundColor: Colors.green,
                                              );
                                            }
                                          },
                                    child: (_submittingAssignment[a.id] == true)
                                        ? const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                height: 16,
                                                width: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Text('Submitting...'),
                                            ],
                                          )
                                        : Text(
                                            _submittedAssignmentIds.contains(a.id) ? 'Submitted' : 'Submit',
                                          ),
                                  ),
                          ),
                        );
                      }).toList(),
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
          if (_initialLoading)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: AppColors.scaffoldBackground.withOpacity(0.65),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 12),
                        Text(
                          'Loading...',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
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
                      _openAddMaterialSheet();
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildActionFab(
                    heroTag: 'assignment-${widget.subject.id}',
                    icon: Icons.assignment_outlined,
                    label: 'Add Assignment',
                    onTap: () {
                      _openAddAssignmentSheet();
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

  Future<({File? file, String? error})> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true,
      );
      if (result == null) return (file: null, error: null);
      final file = result.files.single;
      final path = file.path;
      if (path != null) return (file: File(path), error: null);

      // Some platforms/providers can return bytes but no path.
      final bytes = file.bytes;
      if (bytes == null) return (file: null, error: null);

      final safeName = (file.name.isEmpty ? 'attachment' : file.name)
          .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final tmp = File('${Directory.systemTemp.path}/$safeName');
      await tmp.writeAsBytes(bytes, flush: true);
      return (file: tmp, error: null);
    } catch (e) {
      final msg = e is MissingPluginException
          ? 'File picker plugin not available. Stop the app completely and run again.'
          : 'Failed to pick file';
      return (file: null, error: msg);
    }
  }

  ThemeData _pickerTheme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSurface: const Color(0xFF1C1C1C),
      ),
      dialogBackgroundColor: Colors.white,
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
    );
  }

  Future<void> _openAddAssignmentSheet() async {
    final titleCtl = TextEditingController();
    final descCtl = TextEditingController();
    DateTime? pickedDate;
    File? pickedFile;
    bool creating = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 12,
          right: 12,
          top: 8,
        ),
        child: StatefulBuilder(
          builder: (ctx2, setState2) {
            final dueLabel = pickedDate == null
                ? 'Pick due date'
                : DateFormat.yMMMd().add_jm().format(pickedDate!.toLocal());
            final fileLabel = pickedFile == null
                ? 'No file chosen'
                : pickedFile!.path.split('/').last;

            return Container(
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: const BoxDecoration(gradient: headerGradient),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.assignment_outlined, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Add Assignment',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: creating ? null : () => Navigator.of(ctx2).pop(),
                              icon: const Icon(Icons.close, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: titleCtl,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Title',
                              prefixIcon: const Icon(Icons.title),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: descCtl,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: 'Description',
                              prefixIcon: const Icon(Icons.description_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                    const SizedBox(height: 10),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: creating
                          ? null
                          : () async {
                              final date = await showDatePicker(
                                context: ctx2,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                                builder: (context, child) {
                                  return Theme(
                                    data: _pickerTheme(context),
                                    child: child!,
                                  );
                                },
                              );
                              if (date == null) return;
                              final time = await showTimePicker(
                                context: ctx2,
                                initialTime: TimeOfDay.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: _pickerTheme(context),
                                    child: child!,
                                  );
                                },
                              );
                              if (time == null) return;
                              setState2(() {
                                pickedDate = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 18),
                            const SizedBox(width: 10),
                            Expanded(child: Text(dueLabel)),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.attach_file, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    fileLabel,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (pickedFile != null)
                                  IconButton(
                                    onPressed: creating
                                        ? null
                                        : () => setState2(() => pickedFile = null),
                                    icon: const Icon(Icons.close, size: 18),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: creating
                                ? null
                                : () async {
                                    FocusScope.of(ctx2).unfocus();
                                    final picked = await _pickFile();
                                    if (picked.error != null) {
                                      _showOverlayToast(
                                        message: picked.error!,
                                        backgroundColor: Colors.red,
                                        icon: Icons.error_outline,
                                      );
                                      return;
                                    }
                                    final f = picked.file;
                                    if (f == null) {
                                      _showOverlayToast(
                                        message: 'No file selected',
                                        backgroundColor: Colors.orange,
                                        icon: Icons.warning_amber_outlined,
                                      );
                                      return;
                                    }
                                    setState2(() {
                                      pickedFile = f;
                                    });
                                  },
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Attach'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: creating ? null : () => Navigator.of(ctx2).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: styledButton(
                            creating ? 'Creating...' : 'Create',
                            () async {
                              final title = titleCtl.text.trim();
                              if (title.isEmpty) {
                                _showOverlayToast(
                                  message: 'Title required',
                                  backgroundColor: Colors.red,
                                  icon: Icons.error_outline,
                                );
                                return;
                              }
                              if (pickedDate == null) {
                                _showOverlayToast(
                                  message: 'Please pick a due date',
                                  backgroundColor: Colors.red,
                                  icon: Icons.error_outline,
                                );
                                return;
                              }

                              setState2(() => creating = true);
                              final res = await _assignmentService.createAssignment(
                                title: title,
                                description: descCtl.text.trim(),
                                dueDate: pickedDate!,
                                subjectId: widget.subject.id,
                                attachment: pickedFile,
                              );
                              if (!mounted) return;
                              setState2(() => creating = false);

                              if (res['success'] == true) {
                                Navigator.of(ctx2).pop();
                                await _loadAssignments();
                                IconSnackBar.show(
                                  context,
                                  snackBarType: SnackBarType.success,
                                  label: 'Assignment created',
                                  backgroundColor: Colors.green,
                                );
                              } else {
                                _showOverlayToast(
                                  message: res['error']?.toString() ?? 'Failed to create',
                                  backgroundColor: Colors.red,
                                  icon: Icons.error_outline,
                                );
                              }
                            },
                            creating,
                          ),
                        ),
                      ],
                    ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openAddMaterialSheet() async {
    final titleCtl = TextEditingController();
    final descCtl = TextEditingController();
    File? pickedFile;
    bool creating = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 12,
          right: 12,
          top: 8,
        ),
        child: StatefulBuilder(
          builder: (ctx2, setState2) {
            final fileLabel = pickedFile == null
                ? 'No file chosen'
                : pickedFile!.path.split('/').last;

            return Container(
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: const BoxDecoration(gradient: headerGradient),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.insert_drive_file_outlined, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Add Material',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: creating ? null : () => Navigator.of(ctx2).pop(),
                              icon: const Icon(Icons.close, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: titleCtl,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Title',
                              prefixIcon: const Icon(Icons.title),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: descCtl,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: 'Description',
                              prefixIcon: const Icon(Icons.description_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.attach_file, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          fileLabel,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (pickedFile != null)
                                        IconButton(
                                          onPressed: creating
                                              ? null
                                              : () => setState2(() => pickedFile = null),
                                          icon: const Icon(Icons.close, size: 18),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                height: 44,
                                child: ElevatedButton.icon(
                                  onPressed: creating
                                      ? null
                                      : () async {
                                          FocusScope.of(ctx2).unfocus();
                                          final picked = await _pickFile();
                                          if (picked.error != null) {
                                            _showOverlayToast(
                                              message: picked.error!,
                                              backgroundColor: Colors.red,
                                              icon: Icons.error_outline,
                                            );
                                            return;
                                          }
                                          final f = picked.file;
                                          if (f == null) return;
                                          setState2(() {
                                            pickedFile = f;
                                          });
                                        },
                                  icon: const Icon(Icons.upload_file),
                                  label: const Text('Attach'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: creating ? null : () => Navigator.of(ctx2).pop(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(color: AppColors.primary),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: styledButton(
                                  creating ? 'Creating...' : 'Create',
                                  () async {
                                    final title = titleCtl.text.trim();
                                    if (title.isEmpty) {
                                      _showOverlayToast(
                                        message: 'Title required',
                                        backgroundColor: Colors.red,
                                        icon: Icons.error_outline,
                                      );
                                      return;
                                    }

                                    setState2(() => creating = true);
                                    final res = await _materialService.createMaterial(
                                      title: title,
                                      description: descCtl.text.trim(),
                                      subjectId: widget.subject.id,
                                      file: pickedFile,
                                    );
                                    if (!mounted) return;
                                    setState2(() => creating = false);

                                    if (res['success'] == true) {
                                      Navigator.of(ctx2).pop();
                                      await _loadMaterials();
                                      IconSnackBar.show(
                                        context,
                                        snackBarType: SnackBarType.success,
                                        label: 'Material created',
                                        backgroundColor: Colors.green,
                                      );
                                    } else {
                                      _showOverlayToast(
                                        message: res['error']?.toString() ?? 'Failed to create',
                                        backgroundColor: Colors.red,
                                        icon: Icons.error_outline,
                                      );
                                    }
                                  },
                                  creating,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<bool?> _pickAndSubmit(int assignmentId) async {
    if (_submittingAssignment[assignmentId] == true || _submittedAssignmentIds.contains(assignmentId)) {
      return false;
    }

    final picked = await _pickFile();
    if (picked.error != null) {
      if (!mounted) return false;
      IconSnackBar.show(
        context,
        snackBarType: SnackBarType.alert,
        label: picked.error!,
        backgroundColor: Colors.red,
      );
      return false;
    }
    final file = picked.file;
    if (file == null) {
      if (!mounted) return false;
      IconSnackBar.show(
        context,
        snackBarType: SnackBarType.alert,
        label: 'No file selected',
        backgroundColor: Colors.orange,
      );
      return false;
    }

    if (mounted) {
      setState(() => _submittingAssignment[assignmentId] = true);
    }
    final res = await _assignmentService.submitAssignment(assignmentId: assignmentId, file: file);

    if (!mounted) return false;
    setState(() => _submittingAssignment[assignmentId] = false);

    final ok = res['success'] == true;
    if (ok) {
      setState(() => _submittedAssignmentIds.add(assignmentId));
    } else {
      final err = res['error']?.toString();
      if (err != null && err.isNotEmpty) {
        IconSnackBar.show(
          context,
          snackBarType: SnackBarType.alert,
          label: err,
          backgroundColor: Colors.red,
        );
      }
    }

    return ok;
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
            style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 12),
          ),
        ],
      ),
    );
  }
}