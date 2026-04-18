import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:study_zen/models/submission_model.dart';
import 'package:study_zen/services/assignment_service.dart';
import 'package:study_zen/utils/global.dart';
import 'package:study_zen/utils/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class AssignmentSubmissionsScreen extends StatefulWidget {
  final int assignmentId;
  final String assignmentTitle;

  const AssignmentSubmissionsScreen({
    super.key,
    required this.assignmentId,
    required this.assignmentTitle,
  });

  @override
  State<AssignmentSubmissionsScreen> createState() => _AssignmentSubmissionsScreenState();
}

class _AssignmentSubmissionsScreenState extends State<AssignmentSubmissionsScreen> {
  final AssignmentService _assignmentService = const AssignmentService();

  bool _loading = true;
  List<SubmissionModel> _items = [];
  final Map<int, bool> _openingFile = <int, bool>{};

  Uri? _normalizeUrl(String url) {
    final parsed = Uri.tryParse(url);
    if (parsed == null) return null;
    if (parsed.hasScheme) return parsed;

    // Backend may return a relative path like /api/...
    final base = Uri.tryParse(uri);
    if (base == null) return parsed;
    return base.resolveUri(parsed);
  }

  String _safeFilename(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'submission';
    return trimmed.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }

  String? _extensionFromContentType(String? contentType) {
    if (contentType == null) return null;
    final ct = contentType.split(';').first.trim().toLowerCase();
    switch (ct) {
      case 'application/pdf':
        return 'pdf';
      case 'image/png':
        return 'png';
      case 'image/jpeg':
        return 'jpg';
      case 'application/msword':
        return 'doc';
      case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
        return 'docx';
      default:
        return null;
    }
  }

  String _ensureExtension(String name, String? contentType) {
    if (name.contains('.')) return name;
    final ext = _extensionFromContentType(contentType);
    if (ext == null) return name;
    return '$name.$ext';
  }

  Future<void> _openSubmissionFile(SubmissionModel s) async {
    if (_openingFile[s.id] == true) return;
    setState(() => _openingFile[s.id] = true);

    try {
      // Best path: download with auth + open locally.
      final dl = await _assignmentService.downloadSubmissionFile(s.id);
      if (!mounted) return;

      if (dl.bytes != null) {
        final rawName = _safeFilename(dl.fileName ?? s.fileName ?? 'submission-${s.id}');
        final name = _ensureExtension(rawName, dl.contentType);
        final f = File('${Directory.systemTemp.path}/$name');
        await f.writeAsBytes(dl.bytes!, flush: true);
        if (!mounted) return;

        setState(() => _openingFile[s.id] = false);
        final res = await OpenFilex.open(f.path);
        if (!mounted) return;
        if (res.type != ResultType.done) {
          IconSnackBar.show(
            context,
            snackBarType: SnackBarType.alert,
            label: res.message.trim().isNotEmpty
                ? res.message
                : 'Could not open file on this device',
            backgroundColor: Colors.red,
          );
        }
        return;
      }

      // Download failed: show reason.
      final err = dl.error?.trim();
      final code = dl.statusCode;
      if (err != null && err.isNotEmpty) {
        IconSnackBar.show(
          context,
          snackBarType: SnackBarType.alert,
          label: code == null ? 'Download failed: $err' : 'Download failed ($code): $err',
          backgroundColor: Colors.red,
        );
      }
    } catch (_) {
      // fall through
    }

    // Fallback: try launching URL externally.
    final rawUrl = s.fileUrl;
    final launchUri = (rawUrl == null || rawUrl.isEmpty) ? null : _normalizeUrl(rawUrl);
    bool ok = false;
    if (launchUri != null) {
      try {
        ok = await launchUrl(launchUri, mode: LaunchMode.platformDefault);
      } catch (_) {
        ok = false;
      }
    }

    if (!mounted) return;
    setState(() => _openingFile[s.id] = false);

    if (!ok) {
      if (rawUrl != null && rawUrl.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: rawUrl));
      }
      if (!mounted) return;
      IconSnackBar.show(
        context,
        snackBarType: SnackBarType.alert,
        label: 'Could not open file. Link copied.',
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _assignmentService.fetchSubmissions(widget.assignmentId);
      list.sort((a, b) {
        final aa = a.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bb = b.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bb.compareTo(aa);
      });
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      IconSnackBar.show(
        context,
        snackBarType: SnackBarType.alert,
        label: 'Failed to load submissions',
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
        title: Text('Submissions · ${widget.assignmentTitle}'),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: headerGradient)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 160),
                        Center(child: Text('No submissions yet')),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final s = _items[i];
                        final name = (s.studentName?.trim().isNotEmpty == true)
                            ? s.studentName!
                            : (s.studentId != null ? 'Student #${s.studentId}' : 'Student');
                        final time = s.submittedAt != null
                            ? DateFormat.yMMMd().add_jm().format(s.submittedAt!.toLocal())
                            : 'Unknown time';
                        final hasFile = s.fileUrl?.isNotEmpty == true;
                        final opening = _openingFile[s.id] == true;

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
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.primary.withOpacity(0.08),
                                      child: const Icon(Icons.person_outline, color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                          const SizedBox(height: 2),
                                          Text(time, style: TextStyle(color: Colors.grey.shade700)),
                                        ],
                                      ),
                                    ),
                                    if (s.grade != null && s.grade!.trim().isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondary.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          'Grade: ${s.grade}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (s.comments?.trim().isNotEmpty == true) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    s.comments!,
                                    style: const TextStyle(height: 1.3),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(
                                      hasFile ? Icons.attach_file : Icons.block,
                                      size: 18,
                                      color: hasFile ? AppColors.primary : Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        hasFile ? 'File attached' : 'No file',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: hasFile ? const Color(0xFF1C1C1C) : Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                    if (hasFile)
                                      TextButton(
                                        onPressed: opening ? null : () => _openSubmissionFile(s),
                                        child: opening
                                            ? const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SizedBox(
                                                    height: 14,
                                                    width: 14,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text('Opening...'),
                                                ],
                                              )
                                            : const Text('See'),
                                      ),
                                  ],
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
}
