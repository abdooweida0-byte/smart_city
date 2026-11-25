import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/report.dart';

/// SQLite helper: CRUD for reports and the status history (Timeline).
class DbHelper {
  DbHelper._();
  static final DbHelper instance = DbHelper._();
  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), 'smart_city.db');
    _db = await openDatabase(path, version: 2, onUpgrade: (d, oldV, newV) async {
      if (oldV < 2) await _createPayments(d);
    }, onCreate: (d, v) async {
      await d.execute('''CREATE TABLE reports(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        lat REAL NOT NULL,
        lng REAL NOT NULL,
        image_path TEXT,
        status TEXT NOT NULL,
        reporter TEXT NOT NULL,
        created_at TEXT NOT NULL)''');
      await d.execute('''CREATE TABLE history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        report_id INTEGER NOT NULL,
        status TEXT NOT NULL,
        note TEXT NOT NULL,
        actor TEXT NOT NULL,
        at TEXT NOT NULL,
        FOREIGN KEY(report_id) REFERENCES reports(id) ON DELETE CASCADE)''');
      await _createPayments(d);
    });
    return _db!;
  }

  static Future<void> _createPayments(Database d) => d.execute('''CREATE TABLE IF NOT EXISTS payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        report_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        card_last4 TEXT NOT NULL,
        holder TEXT NOT NULL,
        payer TEXT NOT NULL,
        at TEXT NOT NULL)''');

  // Simulated payment: stores only the last 4 digits (never the full card)
  // and adds an entry to the report Timeline.
  Future<void> insertPayment(Payment p, String reportStatus) async {
    final d = await db;
    await d.transaction((txn) async {
      await txn.insert('payments', p.toMap()..remove('id'));
      await txn.insert(
        'history',
        HistoryEntry(
          reportId: p.reportId,
          status: reportStatus,
          note:
              'دفع تجريبي ${p.amount.toStringAsFixed(2)} ج.م (بطاقة ****${p.cardLast4})',
          actor: p.payer,
          at: p.at,
        ).toMap()
          ..remove('id'),
      );
    });
  }

  Future<List<Payment>> getPayments(int reportId) async {
    final d = await db;
    final rows = await d.query('payments',
        where: 'report_id = ?', whereArgs: [reportId], orderBy: 'at ASC');
    return rows.map(Payment.fromMap).toList();
  }

  // Create: inserts the report and its first Timeline entry.
  Future<int> insertReport(Report r) async {
    final d = await db;
    return d.transaction((txn) async {
      final id = await txn.insert('reports', r.toMap()..remove('id'));
      await txn.insert(
        'history',
        HistoryEntry(
          reportId: id,
          status: 'new',
          note: 'تم إنشاء البلاغ',
          actor: r.reporter,
          at: r.createdAt,
        ).toMap()
          ..remove('id'),
      );
      return id;
    });
  }

  // Read
  Future<List<Report>> getReports() async {
    final d = await db;
    final rows = await d.query('reports', orderBy: 'created_at DESC');
    return rows.map(Report.fromMap).toList();
  }

  Future<List<HistoryEntry>> getHistory(int reportId) async {
    final d = await db;
    final rows = await d.query('history',
        where: 'report_id = ?', whereArgs: [reportId], orderBy: 'at ASC');
    return rows.map(HistoryEntry.fromMap).toList();
  }

  // Update: changes status AND logs it in history, atomically.
  Future<void> updateStatus(
      int reportId, String status, String note, String actor) async {
    final d = await db;
    await d.transaction((txn) async {
      await txn.update('reports', {'status': status},
          where: 'id = ?', whereArgs: [reportId]);
      await txn.insert(
        'history',
        HistoryEntry(
          reportId: reportId,
          status: status,
          note: note,
          actor: actor,
          at: DateTime.now(),
        ).toMap()
          ..remove('id'),
      );
    });
  }

  // Delete
  Future<void> deleteReport(int id) async {
    final d = await db;
    await d.delete('history', where: 'report_id = ?', whereArgs: [id]);
    await d.delete('payments', where: 'report_id = ?', whereArgs: [id]);
    await d.delete('reports', where: 'id = ?', whereArgs: [id]);
  }
}
