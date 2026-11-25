import 'package:flutter_test/flutter_test.dart';
import 'package:smart_city/models/report.dart';

void main() {
  test('Report map round trip', () {
    final r = Report(
      title: 't',
      description: 'd',
      category: 'c',
      lat: 1,
      lng: 2,
      reporter: 'x',
      createdAt: DateTime(2026, 1, 1),
    );
    final back = Report.fromMap(r.toMap());
    expect(back.title, 't');
    expect(back.status, 'new');
  });

  test('Payment map round trip', () {
    final p = Payment(
      reportId: 1,
      amount: 50,
      cardLast4: '4242',
      holder: 'x',
      payer: 'y',
      at: DateTime(2026, 1, 1),
    );
    expect(Payment.fromMap(p.toMap()).cardLast4, '4242');
  });
}
