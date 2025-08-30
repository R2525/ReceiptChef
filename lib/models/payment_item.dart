import 'package:intl/intl.dart';

class PaymentItem {
  final String id;
  final String name;
  final String category;
  final int amount;
  final String? expiryDate;
  final String purchaseDate;
  final String? storageMethod;
  
  PaymentItem({
    required this.id,
    required this.name,
    required this.category,
    required this.amount,
    this.expiryDate,
    required this.purchaseDate,
    this.storageMethod,
  });
}

extension PaymentItemExpiry on PaymentItem {
  DateTime? get expiryAsDate {
    final s = expiryDate;
    if (s == null || s.trim().isEmpty) return null;
    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;
    try { return DateFormat('yyyy-MM-dd').parse(s); } catch (_) { return null; }
  }
  bool get isExpired {
    final dt = expiryAsDate; if (dt == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    return day.isBefore(today);
  }
  String? get expiryFormatted {
    final dt = expiryAsDate; if (dt == null) return null;
    return DateFormat('yyyy-MM-dd').format(dt);
  }
}
