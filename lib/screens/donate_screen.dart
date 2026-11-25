import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/utils.dart';
import '../models/report.dart';
import '../providers/auth_provider.dart';
import '../providers/payment_provider.dart';

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final capped = digits.length > 16 ? digits.substring(0, 16) : digits;
    final buf = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(capped[i]);
    }
    final t = buf.toString();
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final capped = digits.length > 4 ? digits.substring(0, 4) : digits;
    final t = capped.length > 2 ? '${capped.substring(0, 2)}/${capped.substring(2)}' : capped;
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}

class DonateScreen extends StatefulWidget {
  final Report? report;
  const DonateScreen({super.key, this.report});

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController(text: '25');
  final _card = TextEditingController();
  final _expiry = TextEditingController();
  final _cvc = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _card.dispose();
    _expiry.dispose();
    _cvc.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final uid = context.read<AuthProvider>().firebaseUser!.uid;
    final payments = context.read<PaymentProvider>();
    final amount = double.parse(_amount.text.replaceAll(',', '.'));
    final err = await payments.pay(
      userId: uid,
      amount: amount,
      cardNumber: _card.text,
      reportId: widget.report?.id,
      reportTitle: widget.report?.cat.label,
    );
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _busy = false;
        _error = err;
      });
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 56),
        title: const Text('تمت العملية بنجاح'),
        content: Text('شكرًا لدعمك! تم تسجيل مساهمة بقيمة ${amount.toStringAsFixed(2)} جنيه وحفظ الإيصال.'),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('تم')),
        ],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    return Scaffold(
      appBar: AppBar(title: Text(r == null ? 'ادعم صيانة حيّك' : 'ادعم إصلاح البلاغ')),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Card(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('دفع تجريبي'),
              subtitle: Text('لا يتم خصم أي مبلغ حقيقي ولا يتم حفظ بيانات البطاقة'),
            ),
          ),
          const SizedBox(height: 12),
          if (r != null)
            ListTile(
              leading: Icon(r.cat.icon, color: r.cat.color),
              title: Text(r.cat.label),
              subtitle: Text(r.description, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          Text('المبلغ (جنيه)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            for (final v in [10, 25, 50, 100])
              ChoiceChip(
                label: Text('$v'),
                selected: _amount.text == '$v',
                onSelected: (_) => setState(() => _amount.text = '$v'),
              ),
          ]),
          const SizedBox(height: 8),
          TextFormField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'المبلغ', prefixIcon: Icon(Icons.payments)),
            onChanged: (_) => setState(() {}),
            validator: (v) {
              final n = double.tryParse((v ?? '').replaceAll(',', '.'));
              if (n == null || n <= 0) return 'أدخل مبلغًا صحيحًا';
              if (n > 10000) return 'الحد الأقصى 10000';
              return null;
            },
          ),
          const SizedBox(height: 20),
          Text('بيانات البطاقة', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextFormField(
            controller: _card,
            keyboardType: TextInputType.number,
            textDirection: TextDirection.ltr,
            inputFormatters: [_CardNumberFormatter()],
            decoration: const InputDecoration(labelText: 'رقم البطاقة', prefixIcon: Icon(Icons.credit_card)),
            validator: (v) => (v ?? '').replaceAll(' ', '').length < 16 ? 'أدخل 16 رقم' : null,
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _expiry,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                inputFormatters: [_ExpiryFormatter()],
                decoration: const InputDecoration(labelText: 'MM/YY'),
                validator: (v) => expiryValid(v ?? '') ? null : 'تاريخ غير صحيح',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _cvc,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                obscureText: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: const InputDecoration(labelText: 'CVC'),
                validator: (v) => (v ?? '').length < 3 ? 'غير صحيح' : null,
              ),
            ),
          ]),
          const SizedBox(height: 8),
          const Text(
            'بطاقة ناجحة: 4242 4242 4242 4242 · بطاقة مرفوضة: 4000 0000 0000 0002',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textDirection: TextDirection.rtl,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _busy ? null : _pay,
            icon: _busy
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.lock),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('ادفع'),
            ),
          ),
        ]),
      ),
    );
  }
}
