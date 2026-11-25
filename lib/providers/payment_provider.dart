import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/utils.dart';
import '../models/receipt.dart';

class PaymentProvider extends ChangeNotifier {
  static const boxName = 'payments';

  Box get _box => Hive.box(boxName);

  List<Receipt> receiptsFor(String uid) {
    final list = _box.values
        .map((e) => Receipt.fromMap(Map<String, dynamic>.from(e as Map)))
        .where((r) => r.userId == uid)
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  double totalFor(String uid) =>
      receiptsFor(uid).fold<double>(0, (a, r) => a + r.amount);

  Future<String?> pay({
    required String userId,
    required double amount,
    required String cardNumber,
    String? reportId,
    String? reportTitle,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    final digits = cardNumber.replaceAll(' ', '');
    if (digits == '4000000000000002') return 'تم رفض البطاقة';
    if (!luhnValid(digits)) return 'رقم البطاقة غير صحيح';
    final now = DateTime.now();
    final receipt = Receipt(
      id: 'R${now.millisecondsSinceEpoch}',
      userId: userId,
      amount: amount,
      brand: cardBrand(digits),
      last4: digits.substring(digits.length - 4),
      date: now,
      reportId: reportId,
      reportTitle: reportTitle,
    );
    await _box.put(receipt.id, receipt.toMap());
    notifyListeners();
    return null;
  }
}
