class Report {
  final int? id;
  final String title;
  final String description;
  final String category;
  final double lat;
  final double lng;
  final String? imagePath;
  final String status; // new, review, progress, resolved
  final String reporter;
  final DateTime createdAt;

  Report({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.lat,
    required this.lng,
    this.imagePath,
    this.status = 'new',
    required this.reporter,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'lat': lat,
        'lng': lng,
        'image_path': imagePath,
        'status': status,
        'reporter': reporter,
        'created_at': createdAt.toIso8601String(),
      };

  factory Report.fromMap(Map<String, Object?> m) => Report(
        id: m['id'] as int?,
        title: m['title'] as String,
        description: m['description'] as String,
        category: m['category'] as String,
        lat: (m['lat'] as num).toDouble(),
        lng: (m['lng'] as num).toDouble(),
        imagePath: m['image_path'] as String?,
        status: m['status'] as String,
        reporter: m['reporter'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}

class HistoryEntry {
  final int? id;
  final int reportId;
  final String status;
  final String note;
  final String actor;
  final DateTime at;

  HistoryEntry({
    this.id,
    required this.reportId,
    required this.status,
    required this.note,
    required this.actor,
    required this.at,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'report_id': reportId,
        'status': status,
        'note': note,
        'actor': actor,
        'at': at.toIso8601String(),
      };

  factory HistoryEntry.fromMap(Map<String, Object?> m) => HistoryEntry(
        id: m['id'] as int?,
        reportId: m['report_id'] as int,
        status: m['status'] as String,
        note: m['note'] as String,
        actor: m['actor'] as String,
        at: DateTime.parse(m['at'] as String),
      );
}

const statuses = ['new', 'review', 'progress', 'resolved'];

const statusLabels = {
  'new': 'جديد',
  'review': 'قيد المراجعة',
  'progress': 'جاري الحل',
  'resolved': 'تم الحل',
};

const categories = ['حفرة في الشارع', 'إنارة', 'نظافة وقمامة', 'مياه وصرف', 'أخرى'];

class Payment {
  final int? id;
  final int reportId;
  final double amount;
  final String cardLast4;
  final String holder;
  final String payer;
  final DateTime at;

  Payment({
    this.id,
    required this.reportId,
    required this.amount,
    required this.cardLast4,
    required this.holder,
    required this.payer,
    required this.at,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'report_id': reportId,
        'amount': amount,
        'card_last4': cardLast4,
        'holder': holder,
        'payer': payer,
        'at': at.toIso8601String(),
      };

  factory Payment.fromMap(Map<String, Object?> m) => Payment(
        id: m['id'] as int?,
        reportId: m['report_id'] as int,
        amount: (m['amount'] as num).toDouble(),
        cardLast4: m['card_last4'] as String,
        holder: m['holder'] as String,
        payer: m['payer'] as String,
        at: DateTime.parse(m['at'] as String),
      );
}
