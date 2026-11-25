import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/reports_provider.dart';
import '../widgets/report_card.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<ReportsProvider>();
    final uid = context.watch<AuthProvider>().firebaseUser?.uid;
    final mine = rp.reports.where((r) => r.userId == uid).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('بلاغاتي')),
      body: rp.loading
          ? const Center(child: CircularProgressIndicator())
          : mine.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.inbox_outlined, size: 72, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('لسه ما أرسلتش أي بلاغ',
                          style: TextStyle(fontSize: 16)),
                      SizedBox(height: 4),
                      Text('اضغط "بلّغ عن مشكلة" وابدأ',
                          style: TextStyle(color: Colors.grey)),
                    ]),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 6, bottom: 90),
                  itemCount: mine.length,
                  itemBuilder: (_, i) => ReportCard(mine[i]),
                ),
    );
  }
}
