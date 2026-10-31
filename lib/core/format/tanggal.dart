import 'package:intl/intl.dart';

abstract final class FormatTanggal {
  static final _formatLengkap = DateFormat('d MMMM y', 'id_ID');

  /// Format ISO 8601 string atau DateTime ke tanggal baku Indonesia (contoh: "30 Maret 2026")
  static String tanggal(dynamic sumber) {
    if (sumber == null) return '';
    DateTime dt;
    if (sumber is DateTime) {
      dt = sumber;
    } else if (sumber is String) {
      final parsed = DateTime.tryParse(sumber);
      if (parsed == null) return sumber;
      dt = parsed;
    } else {
      return '';
    }
    return _formatLengkap.format(dt);
  }
}

