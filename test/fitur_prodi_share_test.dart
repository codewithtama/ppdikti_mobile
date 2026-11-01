import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pddikti_mobile/core/util/profil_pdf_generator.dart';
import 'package:pddikti_mobile/data/model/detail_kampus.dart';
import 'package:pddikti_mobile/data/model/pencarian_global.dart';
import 'package:pddikti_mobile/fitur/kampus/detail_vm.dart';
import 'package:pddikti_mobile/fitur/kampus/seksi_prodi_kampus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Fitur Baru: Prodi Kampus & Share PDF/WA', () {
    test('1. DetailKampus memetakan jumlahProdi dan rasioDosen dengan tepat', () {
      final json = <String, dynamic>{
        'id_sp': 'test-id-123',
        'kode_pt': '001001',
        'nama_pt': 'Universitas Contoh',
        'status_pt': 'Aktif',
      };

      final detail = DetailKampus.fromJson(
        json,
        biayaKuliahOverride: '2.500.000 - 5.000.000',
        jumlahProdiOverride: 42,
        rasioDosenOverride: '1:25',
      );

      expect(detail.idSp, 'test-id-123');
      expect(detail.jumlahProdi, 42);
      expect(detail.rasioDosen, '1:25');
      expect(detail.biayaKuliah, '2.500.000 - 5.000.000');
    });

    test('2. ProfilPdfGenerator dapat menghasilkan berkas PDF Mahasiswa yang valid', () async {
      const mhs = HasilMahasiswa(
        id: 'mhs-1',
        nama: 'ZALFA ADHIA SALSABILA',
        nim: '211011400001',
        namaPt: 'UNIVERSITAS PAMULANG',
        namaProdi: 'TEKNIK INFORMATIKA',
        jenjang: 'S1',
        status: 'Non-Aktif',
      );

      const detail = DetailMahasiswa(
        ringkasan: mhs,
        statusTerakhir: 'Non-Aktif',
        tanggalMasuk: '2021-09-01',
        riwayatKuliah: [
          RiwayatKuliahSemester(semester: '2021/2022 Ganjil', status: 'Aktif', sks: 20),
          RiwayatKuliahSemester(semester: '2021/2022 Genap', status: 'Aktif', sks: 22),
          RiwayatKuliahSemester(semester: '2022/2023 Ganjil', status: 'Non-Aktif', sks: 0),
        ],
      );

      final pdfFile = await ProfilPdfGenerator.buatPdfMahasiswa(
        detail: detail,
        direktoriTarget: Directory.systemTemp,
      );
      expect(await pdfFile.exists(), isTrue);
      expect(await pdfFile.length(), greaterThan(1000));
    });

    test('3. ProfilPdfGenerator dapat menghasilkan berkas PDF Dosen yang valid', () async {
      const dsn = HasilDosen(
        id: 'dsn-1',
        nama: 'DR. BUDI SANTOSO, M.KOM.',
        nidn: '0412058501',
        namaPt: 'UNIVERSITAS PAMULANG',
        namaProdi: 'TEKNIK INFORMATIKA',
        status: 'Aktif',
        jabatanAkademik: 'Lektor Kepala',
        pendidikanTertinggi: 'S3',
      );

      const detail = DetailDosen(
        ringkasan: dsn,
        jenisKelamin: 'Laki-laki',
        statusIkatanKerja: 'Dosen Tetap',
        riwayatPendidikan: [
          RiwayatPendidikanDosen(
            jenjang: 'S1',
            perguruanTinggi: 'Institut Teknologi Bandung',
            bidangStudi: 'Teknik Informatika',
            tahunLulus: '2007',
          ),
        ],
      );

      final pdfFile = await ProfilPdfGenerator.buatPdfDosen(
        detail: detail,
        direktoriTarget: Directory.systemTemp,
      );
      expect(await pdfFile.exists(), isTrue);
      expect(await pdfFile.length(), greaterThan(1000));
    });

    testWidgets('4. SeksiProdiKampus merender daftar prodi dan filter chip jenjang', (tester) async {
      const prodiSample = [
        HasilProdi(
          id: 'p1',
          nama: 'TEKNIK INFORMATIKA',
          jenjang: 'S1',
          pt: 'UNIVERSITAS PAMULANG',
          akreditasi: 'Baik Sekali',
        ),
        HasilProdi(
          id: 'p2',
          nama: 'SISTEM INFORMASI',
          jenjang: 'S1',
          pt: 'UNIVERSITAS PAMULANG',
          akreditasi: 'Unggul',
        ),
        HasilProdi(
          id: 'p3',
          nama: 'MANAJEMEN',
          jenjang: 'S2',
          pt: 'UNIVERSITAS PAMULANG',
          akreditasi: 'A',
        ),
        HasilProdi(
          id: 'p4',
          nama: 'AKUNTANSI',
          jenjang: 'D3',
          pt: 'UNIVERSITAS PAMULANG',
          akreditasi: 'B',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prodiKampusProvider('UNIVERSITAS PAMULANG').overrideWith(
              (ref) async => prodiSample,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SeksiProdiKampus(
                  namaPt: 'UNIVERSITAS PAMULANG',
                  jumlahProdiTotal: 4,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('DAFTAR PROGRAM STUDI'), findsOneWidget);
      expect(find.text('4 Total'), findsOneWidget);
      expect(find.text('TEKNIK INFORMATIKA'), findsOneWidget);
      expect(find.text('SISTEM INFORMASI'), findsOneWidget);
      expect(find.text('MANAJEMEN'), findsOneWidget);
      expect(find.text('AKUNTANSI'), findsOneWidget);

      // Uji Filter Chip 'S2'
      await tester.tap(find.widgetWithText(FilterChip, 'S2'));
      await tester.pumpAndSettle();

      expect(find.text('MANAJEMEN'), findsOneWidget);
      expect(find.text('TEKNIK INFORMATIKA'), findsNothing);
    });
  });
}
