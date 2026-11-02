import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pddikti_mobile/data/model/detail_kampus.dart';
import 'package:pddikti_mobile/data/model/kampus.dart';
import 'package:pddikti_mobile/data/model/pencarian_global.dart';
import 'package:pddikti_mobile/fitur/kartu_digital/kartu_digital_widget.dart';
import 'package:pddikti_mobile/fitur/komparasi/bar_komparasi_melayang.dart';
import 'package:pddikti_mobile/fitur/komparasi/komparasi_vm.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  group('Komparasi & Kartu Digital Tests', () {
    test('1. KomparasiNotifier menambah dan membatasi maksimal 3 kampus', () {
      final container = ProviderContainer();
      final notifier = container.read(komparasiProvider.notifier);

      final k1 = Kampus(
        kode: '001001',
        nama: 'Institut Teknologi Bandung',
        kelompok: 'PTN',
        pembina: 'Kemdikbud',
        idSp: 'id1',
        akreditasi: 'Unggul',
      );
      final k2 = Kampus(
        kode: '001002',
        nama: 'Universitas Indonesia',
        kelompok: 'PTN',
        pembina: 'Kemdikbud',
        idSp: 'id2',
        akreditasi: 'Unggul',
      );
      final k3 = Kampus(
        kode: '001003',
        nama: 'Universitas Gadjah Mada',
        kelompok: 'PTN',
        pembina: 'Kemdikbud',
        idSp: 'id3',
        akreditasi: 'Unggul',
      );
      final k4 = Kampus(
        kode: '001004',
        nama: 'Institut Teknologi Sepuluh Nopember',
        kelompok: 'PTN',
        pembina: 'Kemdikbud',
        idSp: 'id4',
        akreditasi: 'Unggul',
      );

      expect(notifier.tambahKampus(k1), isTrue);
      expect(notifier.tambahKampus(k2), isTrue);
      expect(notifier.tambahKampus(k3), isTrue);
      expect(container.read(komparasiProvider).daftarKampus.length, 3);
      expect(container.read(komparasiProvider).bisaTambahKampus, isFalse);

      // Kampus ke-4 harus ditolak karena slot maksimal 3
      expect(notifier.tambahKampus(k4), isFalse);
      expect(container.read(komparasiProvider).daftarKampus.length, 3);

      // Toggle hapus jika dipanggil ulang
      expect(notifier.tambahKampus(k1), isFalse);
      expect(container.read(komparasiProvider).daftarKampus.length, 2);
      expect(container.read(komparasiProvider).bisaTambahKampus, isTrue);

      notifier.bersihkanKampus();
      expect(container.read(komparasiProvider).daftarKampus.isEmpty, isTrue);
    });

    test('2. KomparasiNotifier menambah dan menghapus program studi', () {
      final container = ProviderContainer();
      final notifier = container.read(komparasiProvider.notifier);

      const p1 = HasilProdi(
        id: 'p1',
        nama: 'Teknik Informatika',
        jenjang: 'S1',
        pt: 'Institut Teknologi Bandung',
        akreditasi: 'Unggul',
      );
      const p2 = HasilProdi(
        id: 'p2',
        nama: 'Ilmu Komputer',
        jenjang: 'S1',
        pt: 'Universitas Indonesia',
        akreditasi: 'Unggul',
      );

      expect(notifier.tambahProdi(p1), isTrue);
      expect(notifier.tambahProdi(p2), isTrue);
      expect(container.read(komparasiProvider).daftarProdi.length, 2);
      expect(container.read(komparasiProvider).apakahProdiAda('p1'), isTrue);

      notifier.hapusProdi('p1');
      expect(container.read(komparasiProvider).daftarProdi.length, 1);
      expect(container.read(komparasiProvider).apakahProdiAda('p1'), isFalse);
    });

    testWidgets('3. BarKomparasiMelayang tampil saat item dipilih dan hilang saat kosong', (tester) async {
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Center(child: Text('Konten')),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: BarKomparasiMelayang(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Keadaan awal kosong: BarKomparasiMelayang tersembunyi
      expect(find.text('Bandingkan'), findsNothing);

      // Tambahkan kampus dengan detail agar tidak memicu panggilan jaringan asinkron
      container.read(komparasiProvider.notifier).tambahDariDetail(
        const DetailKampus(
          kode: '001001',
          nama: 'Institut Teknologi Bandung',
          kelompok: 'PTN',
          pembina: 'Kemdikbud',
          idSp: 'id1',
        ),
      );
      await tester.pump();

      expect(find.text('Bandingkan'), findsOneWidget);
      expect(find.textContaining('1 Kampus siap dibandingkan'), findsOneWidget);

      // Bersihkan
      container.read(komparasiProvider.notifier).bersihkanSemua();
      await tester.pump();

      expect(find.text('Bandingkan'), findsNothing);
    });

    testWidgets('4. KartuDigitalWidget menampilkan identitas Mahasiswa dan QR Code', (tester) async {
      const detailMhs = DetailMahasiswa(
        ringkasan: HasilMahasiswa(
          id: 'token_mhs_123',
          nama: 'MUHAMMAD TAMA',
          namaPt: 'UNIVERSITAS PAMULANG',
          namaProdi: 'TEKNIK INFORMATIKA',
          nim: '201011400001',
          jenjang: 'S1',
          status: 'Aktif',
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: KartuDigitalWidget(
                mahasiswa: detailMhs,
                tampilkanSisiBelakang: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('MUHAMMAD TAMA'), findsOneWidget);
      expect(find.text('NIM: 201011400001'), findsOneWidget);
      expect(find.text('UNIVERSITAS PAMULANG'), findsOneWidget);
      expect(find.text('S1 - TEKNIK INFORMATIKA'), findsOneWidget);
      expect(find.text('AKTIF'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('5. KartuDigitalWidget sisi belakang menampilkan instruksi validasi QR Code', (tester) async {
      const detailDsn = DetailDosen(
        ringkasan: HasilDosen(
          id: 'token_dsn_456',
          nama: 'DR. IR. TAMA, M.KOM',
          namaPt: 'INSTITUT TEKNOLOGI BANDUNG',
          namaProdi: 'REKAYASA PERANGKAT LUNAK',
          nidn: '0412058001',
          status: 'Aktif',
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: KartuDigitalWidget(
                dosen: detailDsn,
                tampilkanSisiBelakang: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('VALIDASI DOKUMEN DIGITAL'), findsOneWidget);
      expect(find.textContaining('Pindai kode QR menggunakan kamera ponsel'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
    });
  });
}
