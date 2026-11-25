import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/report.dart';
import '../providers/app_provider.dart';

/// Simulated payment (bonus). No real gateway and no money is moved.
/// Only the last 4 digits of the card are stored.
class PaymentScreen extends StatefulWidget {
  final Report report;
  const PaymentScreen({super.key, required this.report});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController(text: '50');
  final _holder = TextEditingController();
  final _number = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  bool _paying = false;

  @override
  void dispose() {
    _amount.dispose();
    _holder.dispose();
    _number.dispose();
    _expiry.dispose();
    _cvv.dispose();
    super.dispose();
  }

  bool _luhn(String digits) {
    var sum = 0;
    var alt = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var n = int.parse(digits[i]);
      if (alt) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alt = !alt;
    }
    return sum % 10 == 0;
  }

  String? _validateExpiry(String? v) {
    final m = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(v ?? '');
    if (m == null) return 'الصيغة MM/YY';
    final month = int.parse(m.group(1)!);
    final year = 2000 + int.parse(m.group(2)!);
    if (month < 1 || month > 12) return 'شهر غير صحيح';
    final now = DateTime.now();
    if (DateTime(year, month + 1).isBefore(now)) return 'البطاقة منتهية';
    return null;
  }

  Future<void> _pay() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _paying = true);
    await Future.delayed(const Duration(seconds: 1)); // fake processing
    final digits = _number.text.replaceAll(' ', '');
    final amount = double.parse(_amount.text.replaceAll(',', '.'));
    if (!mounted) return;
    await context.read<AppProvider>().pay(
          widget.report,
          amount,
          digits.substring(digits.length - 4),
          _holder.text.trim(),
        );
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('تمت العملية'),
        content: Text(
            'تم تسجيل دفع تجريبي بمبلغ ${amount.toStringAsFixed(2)} ج.م.\nلم يتم خصم أي أموال فعلية.'),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('تمام')),
        ],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دعم حل البلاغ')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Colors.amber.shade50,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                    'وضع تجريبي: مفيش بوابة دفع حقيقية ولا فلوس بتتخصم. للتجربة استخدم الرقم 4242 4242 4242 4242.'),
              ),
            ),
            const SizedBox(height: 8),
            Text(widget.report.title,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'المبلغ (ج.م)', border: OutlineInputBorder()),
              validator: (v) {
                final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                if (n == null || n <= 0) return 'اكتب مبلغ صحيح';
                if (n > 100000) return 'المبلغ كبير';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _holder,
              decoration: const InputDecoration(
                  labelText: 'اسم حامل البطاقة', border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().length < 3) ? 'اكتب الاسم' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _number,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
                _CardNumberFormatter(),
              ],
              decoration: const InputDecoration(
                  labelText: 'رقم البطاقة',
                  prefixIcon: Icon(Icons.credit_card),
                  border: OutlineInputBorder()),
              validator: (v) {
                final d = (v ?? '').replaceAll(' ', '');
                if (d.length != 16) return 'الرقم لازم 16 خانة';
                if (!_luhn(d)) return 'رقم البطاقة غير صحيح';
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiry,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                      _ExpiryFormatter(),
                    ],
                    decoration: const InputDecoration(
                        labelText: 'الانتهاء MM/YY',
                        border: OutlineInputBorder()),
                    validator: _validateExpiry,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cvv,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    textDirection: TextDirection.ltr,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: const InputDecoration(
                        labelText: 'CVV', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.length < 3)
                        ? '3 أو 4 أرقام'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _paying ? null : _pay,
              icon: _paying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.lock),
              label: const Text('ادفع (تجريبي)'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final d = newValue.text.replaceAll(' ', '');
    final b = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i > 0 && i % 4 == 0) b.write(' ');
      b.write(d[i]);
    }
    final t = b.toString();
    return TextEditingValue(
        text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final d = newValue.text.replaceAll('/', '');
    final t = d.length > 2 ? '${d.substring(0, 2)}/${d.substring(2)}' : d;
    return TextEditingValue(
        text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}
