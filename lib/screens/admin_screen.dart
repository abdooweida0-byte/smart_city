import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/reports_provider.dart';
import '../widgets/report_card.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  ReportStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<ReportsProvider>();
    final list = rp.reports.where((r) => _filter == null || r.status == _filter).toList()
      ..sort((a, b) {
        final c = b.supportCount.compareTo(a.supportCount);
        return c != 0 ? c : b.createdAt.compareTo(a.createdAt);
      });

    return Scaffold(
      appBar: AppBar(title: const Text('لوحة الإدارة')),
      body: Column(children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text('الكل (${rp.total})'),
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
              ),
              for (final s in ReportStatus.values)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text('${s.label} (${rp.countStatus(s)})'),
                    selected: _filter == s,
                    onSelected: (_) => setState(() => _filter = s),
                  ),
                ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text('مرتبة حسب الأولوية (عدد الداعمين)',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ),
        Expanded(
          child: rp.loading
              ? const Center(child: CircularProgressIndicator())
              : list.isEmpty
                  ? const Center(child: Text('لا توجد بلاغات'))
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 16),
                      itemCount: list.length,
                      itemBuilder: (_, i) => ReportCard(list[i]),
                    ),
        ),
      ]),
    );
  }
}
