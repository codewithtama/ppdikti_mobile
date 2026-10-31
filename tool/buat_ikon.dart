import 'dart:convert';
import 'dart:io';

// Skrip generator ikon aplikasi dari titik kampus (Section 4.5 DESIGN.md)
void main() async {
  final file = File('test/fixtures/locations_full.json');
  if (!file.existsSync()) {
    stdout.writeln('Berkas test/fixtures/locations_full.json tidak ditemukan.');
    return;
  }

  final content = await file.readAsString();
  final dynamic decoded = jsonDecode(content);
  final Map<String, dynamic> json = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  final List<dynamic> list = (json['data'] as List<dynamic>?) ?? <dynamic>[];

  int hitungValid = 0;
  for (final item in list) {
    if (item is Map<String, dynamic>) {
      final lintangStr = (item['lintang'] as String?)?.trim() ?? '';
      final bujurStr = (item['bujur'] as String?)?.trim() ?? '';
      final a = double.tryParse(lintangStr);
      final b = double.tryParse(bujurStr);
      if (a != null && b != null) {
        if ((a >= -11.5 && a <= 6.5 && b >= 94.5 && b <= 141.5) ||
            (b >= -11.5 && b <= 6.5 && a >= 94.5 && a <= 141.5)) {
          hitungValid++;
        }
      }
    }
  }

  stdout.writeln('Total titik terproyeksi untuk ikon: $hitungValid kampus.');
  stdout.writeln('Selesai.');
}
