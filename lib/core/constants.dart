import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class AppConfig {
  static const cloudName = 'YOUR_CLOUD_NAME';
  static const uploadPreset = 'YOUR_UNSIGNED_UPLOAD_PRESET';

  static const packageName = 'app.smartcity.smart_city';

  static const duplicateRadiusMeters = 50.0;

  static const defaultCenter = LatLng(26.1551, 32.7160);

  static const osmTiles = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
}

enum ReportStatus {
  received('تم الاستلام', Icons.inbox, Color(0xFF1E88E5)),
  review('قيد المراجعة', Icons.search, Color(0xFFFB8C00)),
  inProgress('جاري الإصلاح', Icons.build, Color(0xFF8E24AA)),
  resolved('تم الحل', Icons.check_circle, Color(0xFF43A047));

  const ReportStatus(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;

  static ReportStatus fromName(String? n) => ReportStatus.values
      .firstWhere((s) => s.name == n, orElse: () => ReportStatus.received);
}

enum Priority {
  normal('أولوية عادية', Colors.blueGrey),
  high('أولوية مرتفعة', Colors.orange),
  urgent('عاجل', Colors.red);

  const Priority(this.label, this.color);
  final String label;
  final Color color;
}

class Category {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  const Category(this.id, this.label, this.icon, this.color);
}

class Categories {
  static const all = [
    Category('pothole', 'حفر وتشققات طرق', Icons.add_road, Colors.brown),
    Category('lighting', 'إنارة معطلة', Icons.lightbulb, Colors.amber),
    Category('garbage', 'قمامة ونظافة', Icons.delete, Colors.green),
    Category('water', 'مياه وصرف صحي', Icons.water_drop, Colors.blue),
    Category('electric', 'كهرباء وأسلاك', Icons.electrical_services, Colors.deepOrange),
    Category('other', 'أخرى', Icons.report_problem, Colors.grey),
  ];

  static Category byId(String id) =>
      all.firstWhere((c) => c.id == id, orElse: () => all.last);
}
