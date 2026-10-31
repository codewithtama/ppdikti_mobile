import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pddikti_mobile/data/model/kampus.dart';
import 'package:pddikti_mobile/data/model/koordinat.dart';
import 'package:pddikti_mobile/fitur/kampus/indeks_pencarian.dart';

void main() {
  group('Kriteria Selesai Versi 1 (DESIGN.md Bagian 18)', () {
    late List<Kampus> semuaKampus;
    late List<EntriIndeks> semuaIndeks;
    const aliasMap = {'unpam': '041033'};

    setUpAll(() {
      final file = File('test/fixtures/locations_full.json');
      expect(file.existsSync(), isTrue, reason: 'Fixture locations_full.json harus ada');
      final content = file.readAsStringSync();
      final Map<String, dynamic> json = jsonDecode(content) as Map<String, dynamic>;
      final List<dynamic> listRaw = json['data'] as List<dynamic>;

      semuaKampus = listRaw
          .whereType<Map<String, dynamic>>()
          .map((e) => Kampus.fromJson(e))
          .toList();
      semuaIndeks = semuaKampus.map((k) => EntriIndeks(k)).toList();
    });

    test('1. Parsing menghasilkan 4.342 Kampus tanpa spasi di kode dan tanpa kode ganda', () {
      expect(semuaKampus.length, equals(4342));

      final kodeSet = <String>{};
      for (final k in semuaKampus) {
        expect(k.kode.contains(' '), isFalse, reason: 'Kode "${k.kode}" tidak boleh mengandung spasi');
        expect(kodeSet.add(k.kode), isTrue, reason: 'Kode "${k.kode}" tidak boleh duplikat');
      }
    });

    test('2. Normalisasi koordinat: 3.447 layak digambar, 17 dikoreksi, 48 dibuang', () {
      int titikValid = 0;
      int dikoreksi = 0;
      int dibuang = 0;

      final file = File('test/fixtures/locations_full.json');
      final Map<String, dynamic> json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final List<dynamic> listRaw = json['data'] as List<dynamic>;

      for (final item in listRaw) {
        if (item is Map<String, dynamic>) {
          final lStr = ((item['lintang'] as String?) ?? '').trim();
          final bStr = ((item['bujur'] as String?) ?? '').trim();
          final a = double.tryParse(lStr);
          final b = double.tryParse(bStr);

          if (a == null || b == null) {
            continue;
          }

          final normal = normalisasiKoordinat(lStr, bStr);
          if (normal != null) {
            titikValid++;
            if (normal.dikoreksi) {
              dikoreksi++;
            }
          } else {
            dibuang++;
          }
        }
      }

      expect(titikValid, equals(3447));
      expect(dikoreksi, equals(17));
      expect(dibuang, equals(48));
    });

    test('3. Akademi Kepolisian (AKPOL), kode 484001, berstatus dikoreksi', () {
      final akpol = semuaKampus.firstWhere((k) => k.kode == '484001');
      expect(akpol.nama, contains('Akademi Kepolisian'));
      expect(akpol.koordinat, isNotNull);
      expect(akpol.koordinat!.dikoreksi, isTrue);
      expect(akpol.koordinat!.lintang, closeTo(-7.02, 0.05));
      expect(akpol.koordinat!.bujur, closeTo(110.42, 0.05));
    });

    test('4. Pencarian kode 233108 dan akpol', () {
      // Cari 233108
      const q1 = '233108';
      const kataQ1 = [q1];
      final hasil1 = <({Kampus kampus, int skor})>[];
      for (final e in semuaIndeks) {
        final s = hitungSkor(e: e, q: q1, kataQ: kataQ1, aliasMap: aliasMap);
        if (s > 0) hasil1.add((kampus: e.kampus, skor: s));
      }
      hasil1.sort((a, b) => b.skor.compareTo(a.skor));
      expect(hasil1.first.kampus.nama, contains('Sekolah Tinggi Teologi Apostolic'));

      // Cari akpol
      const q2 = 'akpol';
      const kataQ2 = [q2];
      final hasil2 = <({Kampus kampus, int skor})>[];
      for (final e in semuaIndeks) {
        final s = hitungSkor(e: e, q: q2, kataQ: kataQ2, aliasMap: aliasMap);
        if (s > 0) hasil2.add((kampus: e.kampus, skor: s));
      }
      hasil2.sort((a, b) => b.skor.compareTo(a.skor));
      expect(hasil2.any((h) => h.kampus.kode == '484001'), isTrue);
    });

    test('5. Filter kelompok PTN menghasilkan tepat 127 kampus', () {
      final ptn = semuaKampus.where((k) => k.kelompok == 'PTN').toList();
      expect(ptn.length, equals(127));
    });
  });
}
