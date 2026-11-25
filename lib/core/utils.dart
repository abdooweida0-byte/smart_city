import 'package:intl/intl.dart';

String timeAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
  if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
  if (diff.inDays < 30) return 'منذ ${diff.inDays} يوم';
  return DateFormat('d MMM yyyy', 'ar').format(d);
}

String fullDate(DateTime d) => DateFormat('d MMM yyyy - h:mm a', 'ar').format(d);

bool luhnValid(String digits) {
  if (digits.length < 12) return false;
  var sum = 0;
  var alt = false;
  for (var i = digits.length - 1; i >= 0; i--) {
    var n = int.tryParse(digits[i]);
    if (n == null) return false;
    if (alt) {
      n *= 2;
      if (n > 9) n -= 9;
    }
    sum += n;
    alt = !alt;
  }
  return sum % 10 == 0;
}

String cardBrand(String digits) {
  if (digits.startsWith('4')) return 'Visa';
  if (digits.startsWith('5') || digits.startsWith('2')) return 'Mastercard';
  return 'Card';
}

bool expiryValid(String v) {
  final m = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(v);
  if (m == null) return false;
  final month = int.parse(m.group(1)!);
  final year = 2000 + int.parse(m.group(2)!);
  if (month < 1 || month > 12) return false;
  final now = DateTime.now();
  return year > now.year || (year == now.year && month >= now.month);
}
