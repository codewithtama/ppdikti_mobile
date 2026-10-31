import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pddikti_mobile/core/ketentuan/layanan_ketentuan.dart';
import 'package:pddikti_mobile/fitur/ketentuan/ketentuan_layar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Ketentuan & Persyaratan (Gate 10 Detik & Penyimpanan)', () {
    test('1. LayananKetentuan menyimpan dan membaca persetujuan', () async {
      // Simpan persetujuan
      await LayananKetentuan.simpanPersetujuan();

      // Periksa apakah status sudah disetujui
      final disetujui = await LayananKetentuan.sudahSetuju();
      expect(disetujui, isTrue);
    });

    testWidgets('2. KetentuanLayar menampilkan timer countdown dan tombol disable sebelum 10 detik', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: KetentuanLayar(),
        ),
      );

      // Awal buka: Tombol Setuju menampilkan countdown dan disabled
      expect(find.text('Ketentuan & Kebijakan'), findsOneWidget);
      expect(find.text('Tolak & Keluar'), findsOneWidget);
      expect(find.textContaining('Setuju (10s)'), findsOneWidget);

      // Verifikasi tombol setuju tidak bisa diklik saat sisa waktu > 0
      final tombolSetujuFinder = find.widgetWithText(FilledButton, 'Setuju (10s)');
      expect(tombolSetujuFinder, findsOneWidget);
      final tombol = tester.widget<FilledButton>(tombolSetujuFinder);
      expect(tombol.onPressed, isNull);

      // Majukan waktu 5 detik
      await tester.pump(const Duration(seconds: 5));
      expect(find.textContaining('Setuju (5s)'), findsOneWidget);

      // Majukan waktu sampai 10 detik habis
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Sekarang tombol harus berubah menjadi 'Setuju & Lanjut' dan aktif (onPressed != null)
      expect(find.text('Setuju & Lanjut'), findsOneWidget);
      final tombolAktifFinder = find.widgetWithText(FilledButton, 'Setuju & Lanjut');
      final tombolAktif = tester.widget<FilledButton>(tombolAktifFinder);
      expect(tombolAktif.onPressed, isNotNull);
    });
  });
}

