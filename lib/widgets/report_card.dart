import 'package:flutter/material.dart';
import '../core/utils.dart';
import '../models/report.dart';
import '../screens/report_details_screen.dart';
import 'status_chip.dart';

class ReportCard extends StatelessWidget {
  final Report report;
  const ReportCard(this.report, {super.key});

  @override
  Widget build(BuildContext context) {
    final r = report;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ReportDetailsScreen(reportId: r.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                r.imageUrl,
                width: 84,
                height: 84,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 84,
                  height: 84,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(r.cat.icon, size: 18, color: r.cat.color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(r.cat.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  StatusChip(r.status),
                ]),
                const SizedBox(height: 6),
                Text(r.description,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.thumb_up_alt_outlined, size: 14),
                  const SizedBox(width: 4),
                  Text('${r.supportCount}', style: const TextStyle(fontSize: 12)),
                  const Spacer(),
                  Text(timeAgo(r.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
