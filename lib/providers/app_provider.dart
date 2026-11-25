import 'package:flutter/foundation.dart';
import '../models/report.dart';
import '../services/db_helper.dart';

/// Provider state: current user (citizen/admin) and reports list.
class AppProvider extends ChangeNotifier {
  String? userName;
  bool isAdmin = false;
  List<Report> reports = [];
  String filter = 'all';
  bool loading = false;

  bool get loggedIn => userName != null;

  void login(String name, {required bool admin}) {
    userName = name.trim();
    isAdmin = admin;
    notifyListeners();
    loadReports();
  }

  void logout() {
    userName = null;
    isAdmin = false;
    notifyListeners();
  }

  Future<void> loadReports() async {
    loading = true;
    notifyListeners();
    reports = await DbHelper.instance.getReports();
    loading = false;
    notifyListeners();
  }

  List<Report> get visible {
    var list = reports;
    if (!isAdmin) list = list.where((r) => r.reporter == userName).toList();
    if (filter != 'all') list = list.where((r) => r.status == filter).toList();
    return list;
  }

  void setFilter(String f) {
    filter = f;
    notifyListeners();
  }

  Future<void> addReport({
    required String title,
    required String description,
    required String category,
    required double lat,
    required double lng,
    String? imagePath,
  }) async {
    await DbHelper.instance.insertReport(Report(
      title: title,
      description: description,
      category: category,
      lat: lat,
      lng: lng,
      imagePath: imagePath,
      reporter: userName!,
      createdAt: DateTime.now(),
    ));
    await loadReports();
  }

  Future<void> changeStatus(int id, String status, String note) async {
    await DbHelper.instance.updateStatus(id, status, note, '$userName (مسؤول)');
    await loadReports();
  }

  Future<void> pay(Report r, double amount, String last4, String holder) async {
    await DbHelper.instance.insertPayment(
      Payment(
        reportId: r.id!,
        amount: amount,
        cardLast4: last4,
        holder: holder,
        payer: userName!,
        at: DateTime.now(),
      ),
      r.status,
    );
  }

  Future<void> delete(int id) async {
    await DbHelper.instance.deleteReport(id);
    await loadReports();
  }

  Report? byId(int id) {
    for (final r in reports) {
      if (r.id == id) return r;
    }
    return null;
  }

  int count(String status) => visible.where((r) => r.status == status).length;
}
