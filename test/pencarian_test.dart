import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pddikti_mobile/core/net/crypto_pddikti.dart';
import 'package:pddikti_mobile/data/model/pencarian_global.dart';
import 'package:pddikti_mobile/fitur/beranda/peta/peta_painter.dart';

void main() {
  group('Pencarian Terpadu (Mahasiswa, Dosen, Prodi)', () {
    test('1. PddiktiCrypto mampu mengenkripsi dan mendekripsi payload AES-256-CBC', () {
      const plaintext = '{"mahasiswa":[{"nama":"Budi Santoso","nim":"13520001"}]}';
      final encrypted = PddiktiCrypto.enkripsiId(plaintext);
      expect(encrypted.isNotEmpty, isTrue);

      final decrypted = PddiktiCrypto.dekripsiPayload(encrypted);
      expect(decrypted, isA<Map<String, dynamic>>());
      final map = decrypted as Map<String, dynamic>;
      expect(map['mahasiswa'], isNotNull);
      final list = map['mahasiswa'] as List<dynamic>;
      expect(list.first['nama'], equals('Budi Santoso'));
      expect(list.first['nim'], equals('13520001'));
    });

    test('2. Parsing HasilMahasiswa & DetailMahasiswa valid', () {
      final json = {
        'id': 'MHS001',
        'nama': 'Budi Santoso',
        'nim': '13520001',
        'nama_pt': 'Institut Teknologi Bandung',
        'nama_prodi': 'Teknik Informatika',
        'status': 'Aktif',
        'jenjang': 'S1',
        'riwayat_status_kuliah': [
          {'semester': '2020/2021 Ganjil', 'status': 'Aktif', 'sks': 18},
        ],
      };

      final mhs = HasilMahasiswa.fromJson(json);
      expect(mhs.nama, equals('Budi Santoso'));
      expect(mhs.nim, equals('13520001'));
      expect(mhs.namaPt, equals('Institut Teknologi Bandung'));

      final detail = DetailMahasiswa.fromJson(json, fallback: mhs);
      expect(detail.ringkasan.nama, equals('Budi Santoso'));
      expect(detail.riwayatKuliah.length, equals(1));
      expect(detail.riwayatKuliah.first.sks, equals(18));

      final jsonDimas = {
        'id': 'ARZ-06NaPf7ldns6r5PDanfP-RIB29lzOyuJxnpKXs9O9QxD_3G_pvzmO5ABHhnv9mJuww==',
        'nama_pt': 'Universitas Pamulang',
        'kode_pt': '041033  ',
        'kode_prodi': '57201',
        'prodi': 'Sistem Informasi',
        'nama': 'DIMAS ALFA PRATAMA',
        'nim': '241011750041',
        'jenis_daftar': 'Peserta didik baru',
        'jenis_kelamin': 'L',
        'jenjang': 'Sarjana',
        'status_saat_ini': 'Aktif-2025/2026 Genap',
        'tanggal_masuk': '2025-02-23',
      };
      final detailDimas = DetailMahasiswa.fromJson(jsonDimas);
      expect(detailDimas.ringkasan.nama, equals('DIMAS ALFA PRATAMA'));
      expect(detailDimas.ringkasan.namaPt, equals('Universitas Pamulang'));
      expect(detailDimas.jenisKelamin, equals('Laki-laki'));
      expect(detailDimas.tanggalMasuk, equals('2025-02-23'));
      expect(detailDimas.ringkasan.nim, equals('241011750041'));
      expect(detailDimas.jenjangProdi, equals('Sarjana - Sistem Informasi'));
      expect(detailDimas.statusAwal, equals('Peserta didik baru'));
      expect(detailDimas.statusTerakhir, equals('Aktif-2025/2026 Genap'));
    });

    test('3. Parsing HasilDosen & DetailDosen valid', () {
      final json = {
        'id': 'DSN001',
        'nama': 'Prof. Dr. Ir. Budi Santoso, M.Sc.',
        'nidn': '0012056801',
        'nama_pt': 'Institut Teknologi Bandung',
        'nama_prodi': 'Teknik Informatika',
        'status_aktivitas': 'Aktif',
        'jabatan_akademik': 'Guru Besar',
        'pendidikan_tertinggi': 'S3 Doktor',
        'riwayat_pendidikan': [
          {
            'jenjang': 'S1',
            'nama_pt': 'ITB',
            'bidang_studi': 'Teknik Informatika',
            'tahun_lulus': '1992'
          }
        ],
      };

      final dsn = HasilDosen.fromJson(json);
      expect(dsn.nama, equals('Prof. Dr. Ir. Budi Santoso, M.Sc.'));
      expect(dsn.nidn, equals('0012056801'));
      expect(dsn.jabatanAkademik, equals('Guru Besar'));

      final detail = DetailDosen.fromJson(json, fallback: dsn);
      expect(detail.riwayatPendidikan.length, equals(1));
      expect(detail.riwayatPendidikan.first.bidangStudi, equals('Teknik Informatika'));
    });

    test('4. Parsing HasilProdi valid', () {
      final json = {
        'id': 'PRD001',
        'nama': 'Teknik Informatika',
        'jenjang': 'S1',
        'pt': 'Institut Teknologi Bandung',
        'akreditasi': 'Unggul',
        'status': 'Aktif',
        'rasio_dosen_mahasiswa': '1 : 18',
      };

      final prodi = HasilProdi.fromJson(json);
      expect(prodi.nama, equals('Teknik Informatika'));
      expect(prodi.jenjang, equals('S1'));
      expect(prodi.akreditasi, equals('Unggul'));
      expect(prodi.rasioDosenMahasiswa, equals('1 : 18'));
    });

    test('5. Peta Indonesia basemap dimuat dan menghasilkan Path yang valid', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final path = await container.read(petaIndonesiaPathProvider.future);
      expect(path, isNotNull);
      final bounds = path.getBounds();
      expect(bounds.left, greaterThanOrEqualTo(0.0));
      expect(bounds.right, lessThanOrEqualTo(1.0));
      expect(bounds.top, greaterThanOrEqualTo(0.0));
      expect(bounds.bottom, lessThanOrEqualTo(0.40));
    });
  });
}

