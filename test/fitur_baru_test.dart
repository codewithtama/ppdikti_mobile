import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pddikti_mobile/data/model/detail_kampus.dart';
import 'package:pddikti_mobile/data/model/kampus.dart';
import 'package:pddikti_mobile/data/model/publikasi.dart';
import 'package:pddikti_mobile/fitur/kabar/publikasi_thumbnail.dart';
import 'package:pddikti_mobile/fitur/kampus/logo_kampus.dart';

void main() {
  group('Fitur Baru: Publikasi, Logo, Detail Kampus & Filter', () {
    test('1. DetailKampus.fromJson memetakan seluruh field profil sesuai API', () {
      final jsonSample = {
        'kelompok': 'Perguruan Tinggi Swasta',
        'pembina': 'LLDIKTI IV',
        'id_sp': 'test-id-123',
        'kode_pt': '041033',
        'email': 'admin@unpam.ac.id',
        'no_tel': '(021) 7412566',
        'no_fax': '74709855',
        'website': 'www.unpam.ac.id',
        'alamat': 'Jalan Suryakencana No 1 Pamulang',
        'nama_pt': 'Universitas Pamulang',
        'nm_singkat': 'UNPAM',
        'kode_pos': '15417',
        'provinsi_pt': 'Prov. Banten',
        'kab_kota_pt': 'Kota tangerang Selatan',
        'tgl_berdiri_pt': '2000-05-15T00:00:00Z',
        'tgl_sk_pendirian_sp': '2001-08-02T00:00:00Z',
        'sk_pendirian_sp': 'MENDIKBUD 136DO2001',
        'status_pt': 'Aktif',
        'akreditasi_pt': 'Baik Sekali',
        'range_biaya_kuliah': '2.400.000 - 4.900.000',
      };

      final detail = DetailKampus.fromJson(jsonSample);

      expect(detail.kode, '041033');
      expect(detail.nama, 'Universitas Pamulang');
      expect(detail.namaSingkat, 'UNPAM');
      expect(detail.status, 'Aktif');
      expect(detail.akreditasi, 'Baik Sekali');
      expect(detail.biayaKuliah, '2.400.000 - 4.900.000');
      expect(detail.noSkPendirian, 'MENDIKBUD 136DO2001');
      expect(detail.tglBerdiri, '2000-05-15T00:00:00Z');
      expect(detail.tglSkPendirian, '2001-08-02T00:00:00Z');
      expect(detail.telepon, '(021) 7412566');
      expect(detail.fax, '74709855');
      expect(detail.email, 'admin@unpam.ac.id');
      expect(detail.website, 'www.unpam.ac.id');
      expect(detail.alamat, 'Jalan Suryakencana No 1 Pamulang');
      expect(detail.kabKota, 'Kota tangerang Selatan');
      expect(detail.provinsi, 'Prov. Banten');
    });

    test('2. Kampus.deteksiProvinsi memetakan kota dan LLDIKTI ke provinsi resmi', () {
      expect(Kampus.deteksiProvinsi('Kota Yogyakarta', 'LLDIKTI V'), 'D.I. Yogyakarta');
      expect(Kampus.deteksiProvinsi('Kota Banda Aceh', 'LLDIKTI XIII'), 'Aceh');
      expect(Kampus.deteksiProvinsi('Kota Medan', 'LLDIKTI I'), 'Sumatera Utara');
      expect(Kampus.deteksiProvinsi('Kota Tangerang Selatan', 'LLDIKTI IV'), 'Banten');
      expect(Kampus.deteksiProvinsi('Kota Bandung', 'LLDIKTI IV'), 'Jawa Barat');
      expect(Kampus.deteksiProvinsi('Kota Semarang', 'LLDIKTI VI'), 'Jawa Tengah');
      expect(Kampus.deteksiProvinsi('Kota Surabaya', 'LLDIKTI VII'), 'Jawa Timur');
    });

    test('3. LogoKampus.hitungMonogram menghasilkan inisial yang benar', () {
      expect(LogoKampus.hitungMonogram('Universitas Pamulang'), 'P');
      expect(LogoKampus.hitungMonogram('Universitas Gadjah Mada'), 'GM');
      expect(LogoKampus.hitungMonogram('Institut Teknologi Bandung'), 'TB');
    });

    testWidgets('4. PublikasiThumbnail merender sampul buku digital', (tester) async {
      const pub2025 = Publikasi(
        id: '1',
        judul: 'Statistik Pendidikan Tinggi Tahun 2025',
        dibuatPada: '2026-03-30T07:00:00+07:00',
        thumbnail: null,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PublikasiThumbnail(publikasi: pub2025),
          ),
        ),
      );

      expect(find.text('Buku Statistik'), findsOneWidget);
      expect(find.text('2025'), findsOneWidget);
      expect(find.text('Higher Education Statistic'), findsOneWidget);
    });
  });
}

