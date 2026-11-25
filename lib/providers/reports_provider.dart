import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../core/constants.dart';
import '../models/app_user.dart';
import '../models/report.dart';
import '../services/cloudinary_service.dart';

class ReportsProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col => _db.collection('reports');

  List<Report> reports = [];
  bool loading = true;

  StreamSubscription? _sub;
  String? _uid;
  String? _message;
  bool _first = true;
  final Map<String, ReportStatus> _known = {};

  void start(String uid) {
    if (_uid == uid) return;
    _uid = uid;
    _first = true;
    _known.clear();
    _sub?.cancel();
    _sub = _col.orderBy('createdAt', descending: true).snapshots().listen((snap) {
      reports = snap.docs.map(Report.fromDoc).toList();
      for (final r in reports.where((r) => r.userId == uid)) {
        final old = _known[r.id];
        if (!_first && old != null && old != r.status) {
          _message = 'تم تحديث بلاغك (${r.cat.label}): ${r.status.label}';
        }
        _known[r.id] = r.status;
      }
      _first = false;
      loading = false;
      notifyListeners();
    });
  }

  void stop() {
    _sub?.cancel();
    _uid = null;
    reports = [];
    loading = true;
  }

  String? takeMessage() {
    final m = _message;
    _message = null;
    return m;
  }

  Report? byId(String id) {
    for (final r in reports) {
      if (r.id == id) return r;
    }
    return null;
  }

  int get total => reports.length;
  int countStatus(ReportStatus s) => reports.where((r) => r.status == s).length;
  double get resolutionRate =>
      total == 0 ? 0 : countStatus(ReportStatus.resolved) / total * 100;

  Map<String, int> get byCategory {
    final m = <String, int>{};
    for (final r in reports) {
      m[r.category] = (m[r.category] ?? 0) + 1;
    }
    return m;
  }

  double? get avgResolutionHours {
    final done = reports.where((r) => r.resolvedAt != null).toList();
    if (done.isEmpty) return null;
    final mins = done.fold<int>(
        0, (a, r) => a + r.resolvedAt!.difference(r.createdAt).inMinutes);
    return mins / done.length / 60;
  }

  List<Report> nearbyDuplicates(String category, LatLng pos) {
    const dist = Distance();
    final list = reports
        .where((r) =>
            r.category == category &&
            r.status != ReportStatus.resolved &&
            dist.as(LengthUnit.Meter, r.position, pos) <=
                AppConfig.duplicateRadiusMeters)
        .toList();
    list.sort((a, b) => dist
        .as(LengthUnit.Meter, a.position, pos)
        .compareTo(dist.as(LengthUnit.Meter, b.position, pos)));
    return list;
  }

  Future<void> addReport({
    required AppUser user,
    required String category,
    required String description,
    required XFile image,
    required LatLng position,
  }) async {
    final url = await CloudinaryService.upload(image);
    final ref = await _col.add({
      'userId': user.uid,
      'userName': user.name,
      'category': category,
      'description': description,
      'imageUrl': url,
      'lat': position.latitude,
      'lng': position.longitude,
      'status': ReportStatus.received.name,
      'supporters': [user.uid],
      'createdAt': FieldValue.serverTimestamp(),
    });
    await ref.collection('updates').add({
      'status': ReportStatus.received.name,
      'note': 'تم استلام البلاغ وتسجيله في النظام',
      'at': FieldValue.serverTimestamp(),
      'by': user.name,
    });
    await _addPoints(user.uid, 10);
  }

  Future<void> support(Report r, String uid) async {
    if (r.supporters.contains(uid)) return;
    await _col.doc(r.id).update({
      'supporters': FieldValue.arrayUnion([uid])
    });
    await _addPoints(uid, 2);
  }

  Future<void> updateStatus({
    required Report report,
    required ReportStatus status,
    required String note,
    required String adminName,
    XFile? afterImage,
  }) async {
    final data = <String, dynamic>{'status': status.name};
    if (status == ReportStatus.resolved) {
      data['resolvedAt'] = FieldValue.serverTimestamp();
      if (afterImage != null) {
        data['resolvedImageUrl'] = await CloudinaryService.upload(afterImage);
      }
    }
    await _col.doc(report.id).update(data);
    await _col.doc(report.id).collection('updates').add({
      'status': status.name,
      'note': note.isEmpty ? status.label : note,
      'at': FieldValue.serverTimestamp(),
      'by': adminName,
    });
    if (status == ReportStatus.resolved && report.status != ReportStatus.resolved) {
      await _addPoints(report.userId, 20);
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> updatesStream(String id) =>
      _col.doc(id).collection('updates').orderBy('at').snapshots();

  Future<void> _addPoints(String uid, int n) => _db
      .collection('users')
      .doc(uid)
      .set({'points': FieldValue.increment(n)}, SetOptions(merge: true));

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
