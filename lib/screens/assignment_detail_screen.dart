import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
import 'package:intl/intl.dart';
import 'package:study_zen/models/assignment_model.dart';
import 'package:study_zen/screens/assignment_submissions_screen.dart';
import 'package:study_zen/services/assignment_service.dart';
import 'package:study_zen/utils/theme.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final String subjectName;
  final AssignmentModel assignment;
  final bool isTeacher;
  final bool openEditOnOpen;

  const AssignmentDetailScreen({
    super.key,
    required this.subjectName,
    required this.assignment,
    required this.isTeacher,
    this.openEditOnOpen = false,
  });

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  final AssignmentService _assignmentService = const AssignmentService();

  late AssignmentModel _assignment;
  bool _hasChanged = false;
  bool _updating = false;
  bool _deleting = false;
  bool _submitting = false;
  bool _submittedByMe = false;
  bool _initialLoading = false;

  OverlayEntry? _toastEntry;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    _assignment = widget.assignment;
    _initialLoading = !widget.isTeacher;

    if (widget.isTeacher && widget.openEditOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openEditSheet();
      });
    }

    if (!widget.isTeacher) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _checkAlreadySubmitted();
        if (!mounted) return;
        setState(() => _initialLoading = false);
      });
    }
  }

  Widget _blockingLoader({String label = 'Loading...'}) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: AppColors.scaffoldBackground.withOpacity(0.65),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkAlreadySubmitted() async {
    try {
      final subs = await _assignmentService.fetchSubmissions(_assignment.id);
      if (!mounted) return;
      if (subs.isNotEmpty) {
        setState(() => _submittedByMe = true);
      }
    } catch (_) {
      // ignore
    }
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _toastTimer = null;
    _toastEntry?.remove();
    _toastEntry = null;
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

  Future<DateTime?> _pickDueDate(DateTime? current) async {
    final now = DateTime.now();
    final initial = current ?? now.add(const Duration(days: 1));
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(data: _pickerTheme(ctx), child: child!),
    );
    if (pickedDate == null) return null;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (ctx, child) => Theme(data: _pickerTheme(ctx), child: child!),
    );
    if (pickedTime == null) return null;

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  Future<void> _openEditSheet() async {
    if (_updating || _deleting) return;

    final titleCtl = TextEditingController(text: _assignment.title);
    final descCtl = TextEditingController(text: _assignment.description ?? '');
    DateTime? due = _assignment.dueDate;
    File? pickedFile;
    bool saving = false;

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
            final dueLabel = due == null
                ? 'Pick due date'
                : DateFormat.yMMMd().add_jm().format(due!.toLocal());
            final fileLabel = pickedFile == null ? 'No new file chosen' : pickedFile!.path.split('/').last;

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
                              child: const Icon(Icons.edit_outlined, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Edit Assignment',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: saving ? null : () => Navigator.of(ctx2).pop(),
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
                          const Text('Title', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: titleCtl,
                            decoration: InputDecoration(
                              hintText: 'Assignment title',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('Description', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: descCtl,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Optional description',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('Due date', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_month_outlined),
                              label: Text(dueLabel),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: saving
                                  ? null
                                  : () async {
                                      final picked = await _pickDueDate(due);
                                      if (picked == null) return;
                                      setState2(() => due = picked);
                                    },
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('Attachment', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.attach_file, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    fileLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                TextButton(
                                  onPressed: saving
                                      ? null
                                      : () async {
                                          final res = await _pickFile();
                                          if (res.error != null) {
                                            _showOverlayToast(
                                              message: res.error!,
                                              backgroundColor: Colors.red,
                                              icon: Icons.error_outline,
                                            );
                                            return;
                                          }
                                          if (res.file == null) return;
                                          setState2(() => pickedFile = res.file);
                                        },
                                  child: const Text('Choose'),
                                ),
                              ],
                            ),
                          ),
                          if (_assignment.attachmentUrl?.isNotEmpty == true)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Current attachment exists (you can replace it).',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: saving ? null : () => Navigator.of(ctx2).pop(),
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
                                child: SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    ),
                                    onPressed: saving
                                        ? null
                                        : () async {
                                            final title = titleCtl.text.trim();
                                            if (title.isEmpty) {
                                              _showOverlayToast(
                                                message: 'Title required',
                                                backgroundColor: Colors.red,
                                                icon: Icons.error_outline,
                                              );
                                              return;
                                            }
                                            if (due == null) {
                                              _showOverlayToast(
                                                message: 'Please pick a due date',
                                                backgroundColor: Colors.red,
                                                icon: Icons.error_outline,
                                              );
                                              return;
                                            }

                                            setState2(() => saving = true);
                                            setState(() => _updating = true);
                                            final res = await _assignmentService.updateAssignment(
                                              assignmentId: _assignment.id,
                                              title: title,
                                              description: descCtl.text.trim(),
                                              dueDate: due,
                                              attachment: pickedFile,
                                            );
                                            if (!mounted) return;
                                            setState(() => _updating = false);
                                            setState2(() => saving = false);

                                            if (res['success'] == true) {
                                              final updated = res['assignment'];
                                              if (updated is AssignmentModel) {
                                                setState(() {
                                                  _assignment = updated;
                                                  _hasChanged = true;
                                                });
                                              }
                                              Navigator.of(ctx2).pop();
                                              IconSnackBar.show(
                                                context,
                                                snackBarType: SnackBarType.success,
                                                label: 'Assignment updated',
                                                backgroundColor: Colors.green,
                                              );
                                            } else {
                                              _showOverlayToast(
                                                message: res['error']?.toString() ?? 'Failed to update',
                                                backgroundColor: Colors.red,
                                                icon: Icons.error_outline,
                                              );
                                            }
                                          },
                                    child: Text(saving ? 'Saving...' : 'Save'),
                                  ),
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

  Future<void> _confirmDelete() async {
    if (_deleting || _updating) return;
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

    setState(() => _deleting = true);
    final res = await _assignmentService.deleteAssignment(_assignment.id);
    if (!mounted) return;
    setState(() => _deleting = false);

    if (res['success'] == true) {
      IconSnackBar.show(
        context,
        snackBarType: SnackBarType.success,
        label: 'Assignment deleted',
        backgroundColor: Colors.green,
      );
      Navigator.of(context).pop(true);
    } else {
      _showOverlayToast(
        message: res['error']?.toString() ?? 'Failed to delete',
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
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

      final bytes = file.bytes;
      if (bytes == null) return (file: null, error: null);

      final safeName = (file.name.isEmpty ? 'submission' : file.name)
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

  Future<void> _submit() async {
    if (_submitting || _submittedByMe) return;
    FocusScope.of(context).unfocus();

    setState(() => _submitting = true);

    final picked = await _pickFile();
    if (picked.error != null) {
      if (mounted) setState(() => _submitting = false);
      _showOverlayToast(
        message: picked.error!,
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
      return;
    }
    final file = picked.file;
    if (file == null) {
      if (mounted) setState(() => _submitting = false);
      _showOverlayToast(
        message: 'No file selected',
        backgroundColor: Colors.orange,
        icon: Icons.warning_amber_outlined,
      );
      return;
    }

    final res = await _assignmentService.submitAssignment(
      assignmentId: _assignment.id,
      file: file,
    );

    if (!mounted) return;

    setState(() => _submitting = false);

    if (res['success'] == true) {
      setState(() {
        _submittedByMe = true;
        _hasChanged = true;
      });
      IconSnackBar.show(
        context,
        snackBarType: SnackBarType.success,
        label: 'Submitted',
        backgroundColor: Colors.green,
      );
    } else {
      _showOverlayToast(
        message: res['error']?.toString() ?? 'Failed to submit',
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = _assignment;
    final due = a.dueDate != null ? DateFormat.yMMMd().add_jm().format(a.dueDate!.toLocal()) : 'No due date';
    final created = a.createdAt != null ? DateFormat.yMMMd().add_jm().format(a.createdAt!.toLocal()) : null;

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_hasChanged);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: Text(a.title),
          flexibleSpace: Container(decoration: const BoxDecoration(gradient: headerGradient)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_hasChanged),
          ),
          actions: widget.isTeacher
              ? [
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: (_updating || _deleting) ? null : _openEditSheet,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: (_updating || _deleting) ? null : _confirmDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ]
              : null,
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Subject', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(widget.subjectName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Text('Due', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(due),
                  if (created != null) ...[
                    const SizedBox(height: 12),
                    Text('Created', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(created),
                  ],
                  const SizedBox(height: 12),
                  Text('Description', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(a.description?.trim().isNotEmpty == true ? a.description! : 'No description'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
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
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.08),
                    child: const Icon(Icons.attach_file, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      a.attachmentUrl?.isNotEmpty == true ? 'Attachment available' : 'No attachment',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (a.attachmentUrl?.isNotEmpty == true)
                    TextButton(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: a.attachmentUrl!));
                        if (!mounted) return;
                        IconSnackBar.show(
                          context,
                          snackBarType: SnackBarType.success,
                          label: 'Attachment link copied',
                          backgroundColor: Colors.green,
                        );
                      },
                      child: const Text('Copy link'),
                    ),
                ],
              ),
            ),
            if (widget.isTeacher) ...[
              const SizedBox(height: 14),
              Container(
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
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.08),
                      child: const Icon(Icons.people_outline, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Submission info',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AssignmentSubmissionsScreen(
                              assignmentId: _assignment.id,
                              assignmentTitle: _assignment.title,
                            ),
                          ),
                        );
                      },
                      child: const Text('View'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            if (!widget.isTeacher)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: (_submitting || _submittedByMe) ? null : _submit,
                  child: _submitting
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
                            SizedBox(width: 10),
                            Text('Submitting...'),
                          ],
                        )
                      : Text(_submittedByMe ? 'Submitted' : 'Submit assignment'),
                ),
              ),
                ],
              ),
            ),
            if (_initialLoading) _blockingLoader(),
            if (_updating || _deleting) _blockingLoader(label: 'Loading...'),
          ],
        ),
      ),
    );
  }
}
