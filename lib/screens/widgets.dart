import 'package:flutter/material.dart';

Color statusColor(String s) {
  switch (s) {
    case 'new':
      return Colors.red;
    case 'review':
      return Colors.orange;
    case 'progress':
      return Colors.blue;
    default:
      return Colors.green;
  }
}

class StatusChip extends StatelessWidget {
  final String status;
  final String label;
  const StatusChip({super.key, required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c),
      ),
      child: Text(label, style: TextStyle(color: c, fontSize: 12)),
    );
  }
}
