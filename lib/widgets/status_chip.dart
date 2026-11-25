import 'package:flutter/material.dart';
import '../core/constants.dart';

class StatusChip extends StatelessWidget {
  final ReportStatus status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(status.icon, size: 14, color: status.color),
        const SizedBox(width: 4),
        Text(status.label,
            style: TextStyle(
                fontSize: 12, color: status.color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
