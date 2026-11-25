import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role;
  final int points;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.points,
  });

  bool get isAdmin => role == 'admin';

  static const levels = [
    (0, 'مواطن جديد'),
    (50, 'مواطن نشيط'),
    (150, 'مواطن مثالي'),
    (300, 'بطل المدينة'),
  ];

  int get levelIndex {
    var i = 0;
    for (var k = 0; k < levels.length; k++) {
      if (points >= levels[k].$1) i = k;
    }
    return i;
  }

  String get levelName => levels[levelIndex].$2;
  int? get nextLevelAt =>
      levelIndex + 1 < levels.length ? levels[levelIndex + 1].$1 : null;

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return AppUser(
      uid: d.id,
      name: m['name'] ?? '',
      email: m['email'] ?? '',
      role: m['role'] ?? 'citizen',
      points: (m['points'] as num?)?.toInt() ?? 0,
    );
  }
}
