import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/utils.dart';
import '../providers/auth_provider.dart';
import '../providers/payment_provider.dart';

class ReceiptsScreen extends StatelessWidget {
  const ReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().firebaseUser?.uid ?? '';
    final pp = context.watch<PaymentProvider>();
    final list = pp.receiptsFor(uid);

    return Scaffold(
      appBar: AppBar(title: const Text('إيصالاتي')),
      body: list.isEmpty
          ? const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.receipt_long, size: 72, color: Colors.grey),
                SizedBox(height: 12),
                Text('لا توجد إيصالات بعد'),
              ]),
            )
          : Column(children: [
              Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  leading: const Icon(Icons.favorite, color: Colors.red),
                  title: const Text('إجمالي مساهماتك'),
                  trailing: Text('${pp.totalFor(uid).toStringAsFixed(2)} جنيه',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final r = list[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.receipt)),
                        title: Text('${r.amount.toStringAsFixed(2)} جنيه'),
                        subtitle: Text(
                          '${r.reportTitle ?? 'دعم صيانة الحي'}\n'
                          '${r.brand} •••• ${r.last4} · ${fullDate(r.date)}\n'
                          '#${r.id}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
            ]),
    );
  }
}
