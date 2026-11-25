class Receipt {
  final String id;
  final String userId;
  final double amount;
  final String brand;
  final String last4;
  final DateTime date;
  final String? reportId;
  final String? reportTitle;

  const Receipt({
    required this.id,
    required this.userId,
    required this.amount,
    required this.brand,
    required this.last4,
    required this.date,
    this.reportId,
    this.reportTitle,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'amount': amount,
        'brand': brand,
        'last4': last4,
        'date': date.toIso8601String(),
        'reportId': reportId,
        'reportTitle': reportTitle,
      };

  factory Receipt.fromMap(Map<String, dynamic> m) => Receipt(
        id: m['id'] as String,
        userId: m['userId'] as String,
        amount: (m['amount'] as num).toDouble(),
        brand: m['brand'] as String,
        last4: m['last4'] as String,
        date: DateTime.parse(m['date'] as String),
        reportId: m['reportId'] as String?,
        reportTitle: m['reportTitle'] as String?,
      );
}
