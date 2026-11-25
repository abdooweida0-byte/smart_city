import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import '../models/report.dart';
import '../providers/auth_provider.dart';
import '../providers/reports_provider.dart';
import '../widgets/status_chip.dart';
import 'donate_screen.dart';
import '../widgets/status_update_sheet.dart';

class ReportDetailsScreen extends StatelessWidget {
  final String reportId;
  const ReportDetailsScreen({super.key, required this.reportId});

  Widget _img(String url, {double height = 220}) => Image.network(
        url,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (c, child, p) => p == null
            ? child
            : SizedBox(
                height: height,
                child: const Center(child: CircularProgressIndicator())),
        errorBuilder: (_, __, ___) => Container(
          height: height,
          color: Colors.grey.shade300,
          child: const Icon(Icons.image_not_supported, size: 48),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<ReportsProvider>();
    final user = context.watch<AuthProvider>().appUser;
    final Report? r = rp.byId(reportId);

    if (r == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل البلاغ')),
        body: Center(
          child: rp.loading
              ? const CircularProgressIndicator()
              : const Text('البلاغ غير موجود'),
        ),
      );
    }

    final supported = user != null && r.supporters.contains(user.uid);

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل البلاغ')),
      floatingActionButton: (user?.isAdmin ?? false)
          ? FloatingActionButton.extended(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => StatusUpdateSheet(report: r),
              ),
              icon: const Icon(Icons.edit),
              label: const Text('تحديث الحالة'),
            )
          : null,
      body: ListView(padding: const EdgeInsets.only(bottom: 100), children: [
        _img(r.imageUrl),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(r.cat.icon, color: r.cat.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(r.cat.label,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
              StatusChip(r.status),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              Chip(
                visualDensity: VisualDensity.compact,
                avatar: Icon(Icons.flag, size: 16, color: r.priority.color),
                label: Text(r.priority.label),
              ),
              Chip(
                visualDensity: VisualDensity.compact,
                avatar: const Icon(Icons.person, size: 16),
                label: Text(r.userName.isEmpty ? 'مواطن' : r.userName),
              ),
              Chip(
                visualDensity: VisualDensity.compact,
                avatar: const Icon(Icons.schedule, size: 16),
                label: Text(timeAgo(r.createdAt)),
              ),
            ]),
            const SizedBox(height: 12),
            Text(r.description, style: const TextStyle(fontSize: 16, height: 1.5)),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: (supported || user == null)
                  ? null
                  : () => context.read<ReportsProvider>().support(r, user.uid),
              icon: Icon(supported ? Icons.thumb_up : Icons.thumb_up_alt_outlined),
              label: Text(supported
                  ? 'دعمت هذا البلاغ (${r.supportCount})'
                  : 'ادعم البلاغ (${r.supportCount})'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DonateScreen(report: r)),
              ),
              icon: const Icon(Icons.favorite_border),
              label: const Text('ادعم إصلاح هذا البلاغ'),
            ),
            const SizedBox(height: 20),
            Text('الموقع', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 170,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: r.position,
                    initialZoom: 16,
                    interactionOptions:
                        const InteractionOptions(flags: InteractiveFlag.none),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: AppConfig.osmTiles,
                      userAgentPackageName: AppConfig.packageName,
                    ),
                    MarkerLayer(markers: [
                      Marker(
                        point: r.position,
                        width: 40,
                        height: 40,
                        alignment: Alignment.topCenter,
                        child: Icon(Icons.location_on,
                            color: r.status.color, size: 40),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
            if (r.resolvedImageUrl != null) ...[
              const SizedBox(height: 20),
              Text('قبل وبعد الإصلاح',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: Column(children: [
                    ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _img(r.imageUrl, height: 130)),
                    const Text('قبل'),
                  ]),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(children: [
                    ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _img(r.resolvedImageUrl!, height: 130)),
                    const Text('بعد'),
                  ]),
                ),
              ]),
            ],
            const SizedBox(height: 20),
            Text('مسار البلاغ', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: context.read<ReportsProvider>().updatesStream(r.id),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                return Column(children: [
                  for (var i = 0; i < docs.length; i++)
                    _TimelineTile(
                      data: docs[i].data(),
                      isLast: i == docs.length - 1,
                    ),
                ]);
              },
            ),
          ]),
        ),
      ]),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isLast;
  const _TimelineTile({required this.data, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final s = ReportStatus.fromName(data['status']);
    final at = (data['at'] as Timestamp?)?.toDate();
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Column(children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: s.color,
            child: Icon(s.icon, size: 16, color: Colors.white),
          ),
          if (!isLast)
            Expanded(child: Container(width: 2, color: Colors.grey.shade300)),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.label,
                  style: TextStyle(fontWeight: FontWeight.bold, color: s.color)),
              if ((data['note'] ?? '').toString().isNotEmpty)
                Text(data['note']),
              Text(
                '${at == null ? 'الآن' : fullDate(at)} · ${data['by'] ?? ''}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
