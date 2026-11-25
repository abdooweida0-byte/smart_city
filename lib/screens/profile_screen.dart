import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../models/report.dart';
import '../providers/auth_provider.dart';
import '../providers/reports_provider.dart';
import '../core/constants.dart';
import 'donate_screen.dart';
import 'receipts_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().appUser;
    final rp = context.watch<ReportsProvider>();
    if (user == null) return const SizedBox.shrink();

    final mine = rp.reports.where((r) => r.userId == user.uid).toList();
    final resolved = mine.where((r) => r.status == ReportStatus.resolved).length;
    final next = user.nextLevelAt;
    final prev = AppUser.levels[user.levelIndex].$1;
    final progress = next == null ? 1.0 : (user.points - prev) / (next - prev);

    final badges = <(IconData, String, bool)>[
      (Icons.flag, 'أول بلاغ', mine.isNotEmpty),
      (Icons.local_fire_department, '5 بلاغات', mine.length >= 5),
      (Icons.groups, 'بلاغ مدعوم', mine.any((Report r) => r.supportCount >= 5)),
      (Icons.verified, 'بلاغ تم حله', resolved > 0),
      (Icons.emoji_events, '100 نقطة', user.points >= 100),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(
          child: CircleAvatar(
            radius: 42,
            child: Text(
              user.name.isEmpty ? '?' : user.name.characters.first,
              style: const TextStyle(fontSize: 34),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(user.name,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ),
        Center(child: Text(user.email, style: const TextStyle(color: Colors.grey))),
        if (user.isAdmin)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 6),
              child: Chip(
                  avatar: Icon(Icons.admin_panel_settings, size: 16),
                  label: Text('مسؤول')),
            ),
          ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.stars, color: Colors.amber),
                const SizedBox(width: 8),
                Text(user.levelName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${user.points} نقطة'),
              ]),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 6),
              Text(
                next == null
                    ? 'وصلت لأعلى مستوى'
                    : 'باقي ${next - user.points} نقطة للمستوى التالي',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _Mini('بلاغاتي', '${mine.length}', Icons.report)),
          const SizedBox(width: 10),
          Expanded(child: _Mini('تم حلها', '$resolved', Icons.check_circle)),
        ]),
        const SizedBox(height: 20),
        Text('الشارات', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final b in badges)
            Opacity(
              opacity: b.$3 ? 1 : .35,
              child: Chip(
                avatar: Icon(b.$1, size: 18, color: b.$3 ? Colors.amber.shade800 : null),
                label: Text(b.$2),
              ),
            ),
        ]),
        const SizedBox(height: 8),
        const Text('+10 نقاط لكل بلاغ · +2 لكل دعم · +20 لما بلاغك يتحل',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 16),
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.favorite, color: Colors.red),
              title: const Text('ادعم صيانة حيّك'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DonateScreen()),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('إيصالاتي'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReceiptsScreen()),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () {
            context.read<ReportsProvider>().stop();
            context.read<AuthProvider>().signOut();
          },
          icon: const Icon(Icons.logout),
          label: const Text('تسجيل الخروج'),
        ),
      ]),
    );
  }
}

class _Mini extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _Mini(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Text(value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Text(label),
          ]),
        ),
      );
}
