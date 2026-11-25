import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/report.dart';
import '../providers/auth_provider.dart';
import '../providers/reports_provider.dart';

class StatusUpdateSheet extends StatefulWidget {
  final Report report;
  const StatusUpdateSheet({super.key, required this.report});

  @override
  State<StatusUpdateSheet> createState() => _StatusUpdateSheetState();
}

class _StatusUpdateSheetState extends State<StatusUpdateSheet> {
  late ReportStatus _status = widget.report.status;
  final _note = TextEditingController();
  XFile? _after;
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final rp = context.read<ReportsProvider>();
    final admin = context.read<AuthProvider>().appUser!;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      await rp.updateStatus(
        report: widget.report,
        status: _status,
        note: _note.text.trim(),
        adminName: admin.name,
        afterImage: _status == ReportStatus.resolved ? _after : null,
      );
      nav.pop();
      messenger.showSnackBar(const SnackBar(content: Text('تم تحديث حالة البلاغ')));
    } catch (e) {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text('تعذر التحديث: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('تحديث حالة البلاغ',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in ReportStatus.values)
                ChoiceChip(
                  avatar: Icon(s.icon, size: 18, color: s.color),
                  label: Text(s.label),
                  selected: _status == s,
                  onSelected: (_) => setState(() => _status = s),
                ),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'ملاحظة للمواطن (اختياري)',
                  alignLabelWithHint: true),
            ),
            if (_status == ReportStatus.resolved) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final f = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 60,
                      maxWidth: 1280);
                  if (f != null) setState(() => _after = f);
                },
                icon: const Icon(Icons.photo),
                label: Text(_after == null
                    ? 'أضف صورة "بعد الإصلاح"'
                    : 'تم اختيار الصورة: ${_after!.name}'),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('حفظ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
