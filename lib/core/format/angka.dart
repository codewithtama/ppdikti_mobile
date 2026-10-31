import 'package:intl/intl.dart';

abstract final class FormatAngka {
  static final _ribuan = NumberFormat('#,##0', 'id_ID');
  static final _desimalSatu = NumberFormat('#,##0.0', 'id_ID');

  /// Format angka integer atau bulat dengan pemisah ribuan titik (contoh: 9.967.487)
  static String ribuan(num nilai) => _ribuan.format(nilai);

  /// Format persen kelulusan dengan pembulatan satu desimal (contoh: 74,1%)
  static String persenSatuDesimal(num nilai) => '${_desimalSatu.format(nilai)}%';

  /// Parse string koma desimal Indonesia ("52,88") ke double
  static double? parseDesimalKoma(String? teks) {
    if (teks == null || teks.trim().isEmpty) return null;
    final bersih = teks.trim().replaceAll(',', '.');
    return double.tryParse(bersih);
  }

  /// Format koordinat desimal titik dengan 5 digit presisi (contoh: -6.18320)
  static String koordinat(double nilai) => nilai.toStringAsFixed(5);
}

