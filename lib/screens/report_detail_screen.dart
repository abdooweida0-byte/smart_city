import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/report.dart';
import '../providers/app_provider.dart';
import '../services/db_helper.dart';
import 'payment_screen.dart';
import 'widgets.dart';

class ReportDetailScreen extends StatefulWidget {
  final int reportId;
  const ReportDetailScreen({super.key, required this.reportId});
  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  List<HistoryEntry> _history = [];
  List<Payment> _payments = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final h = await DbHelper.instance.getHistory(widget.reportId);
    final pay = await DbHelper.instance.getPayments(widget.reportId);
    if (mounted) {
      setState(() {
        _history = h;
        _payments = pay;
      });
    }
  }

  Future<void> _changeStatus(Report r) async {
    final note = TextEditingController();
    String sel = r.status;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('تغيير حالة البلاغ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final s in statuses)
                RadioListTile<String>(
                  value: s,
                  groupValue: sel,
                  title: Text(statusLabels[s]!),
                  onChanged: (v) => setS(() => sel = v!),
                ),
              TextField(
                controller: note,
                decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('حفظ')),
          ],
        ),
      ),
    );
    if (ok == true && sel != r.status && mounted) {
      final text = note.text.trim().isEmpty
          ? 'تم تغيير الحالة إلى ${statusLabels[sel]}'
          : note.text.trim();
      await context.read<AppProvider>().changeStatus(r.id!, sel, text);
      await _loadHistory();
    }
  }

  Future<void> _delete(Report r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف البلاغ؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<AppProvider>().delete(r.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final r = app.byId(widget.reportId);
    if (r == null) return const Scaffold(body: SizedBox());
    final fmt = DateFormat('y/MM/dd HH:mm');
    final img = r.imagePath;
    final canDelete = app.isAdmin || (r.reporter == app.userName && r.status == 'new');
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل البلاغ'),
        actions: [
          if (canDelete)
            IconButton(
                onPressed: () => _delete(r), icon: const Icon(Icons.delete)),
        ],
      ),
      floatingActionButton: app.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _changeStatus(r),
              icon: const Icon(Icons.edit),
              label: const Text('تغيير الحالة'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          if (img != null && File(img).existsSync())
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(img), height: 200, fit: BoxFit.cover),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: Text(r.title,
                      style: Theme.of(context).textTheme.titleLarge)),
              StatusChip(status: r.status, label: statusLabels[r.status]!),
            ],
          ),
          const SizedBox(height: 6),
          Text('${r.category} • بواسطة ${r.reporter} • ${fmt.format(r.createdAt)}',
              style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 10),
          Text(r.description),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(r.lat, r.lng),
                  initialZoom: 16,
                  interactionOptions:
                      const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.smartcity.smart_city',
                  ),
                  MarkerLayer(markers: [
                    Marker(
                      point: LatLng(r.lat, r.lng),
                      width: 44,
                      height: 44,
                      child: Icon(Icons.location_on,
                          size: 44, color: statusColor(r.status)),
                    ),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => PaymentScreen(report: r)));
              await _loadHistory();
            },
            icon: const Icon(Icons.payment),
            label: const Text('ادعم حل البلاغ (دفع تجريبي)'),
          ),
          if (_payments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                  'المدفوعات: ${_payments.length} • الإجمالي ${_payments.fold<double>(0, (a, b) => a + b.amount).toStringAsFixed(2)} ج.م',
                  style: TextStyle(color: Colors.grey.shade700)),
            ),
          const SizedBox(height: 20),
          Text('سجل البلاغ (Timeline)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (var i = 0; i < _history.length; i++)
            _TimelineRow(
              entry: _history[i],
              isLast: i == _history.length - 1,
              time: fmt.format(_history[i].at),
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final HistoryEntry entry;
  final bool isLast;
  final String time;
  const _TimelineRow(
      {required this.entry, required this.isLast, required this.time});

  @override
  Widget build(BuildContext context) {
    final c = statusColor(entry.status);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: Colors.grey.shade300)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(statusLabels[entry.status]!,
                      style: TextStyle(fontWeight: FontWeight.bold, color: c)),
                  Text(entry.note),
                  Text('$time • ${entry.actor}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
