import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pddikti_mobile/core/theme/tema.dart';
import 'package:pddikti_mobile/data/model/kampus.dart';
import 'package:pddikti_mobile/data/model/koordinat.dart';
import 'package:pddikti_mobile/data/sumber/db_lokal.dart';
import 'package:pddikti_mobile/fitur/beranda/grafik_distribusi_kampus.dart';
import 'package:pddikti_mobile/fitur/beranda/peta/kluster_peta.dart';
import 'package:pddikti_mobile/fitur/komparasi/grafik_komparasi_widget.dart';
import 'package:pddikti_mobile/fitur/komparasi/komparasi_model.dart';

void main() {
  final contohKampus = [
    const Kampus(
      idSp: '1',
      kode: '001002',
      nama: 'Universitas Indonesia',
      kelompok: 'PTN',
      pembina: 'Kemdiktisaintek',
      akreditasi: 'Unggul',
      koordinat: Koordinat(-6.3606, 106.8272),
    ),
    const Kampus(
      idSp: '2',
      kode: '001001',
      nama: 'Institut Teknologi Bandung',
      kelompok: 'PTN',
      pembina: 'Kemdiktisaintek',
      akreditasi: 'Unggul',
      koordinat: Koordinat(-6.8915, 107.6107),
    ),
    const Kampus(
      idSp: '3',
      kode: '041033',
      nama: 'Universitas Pamulang',
      kelompok: 'PTS',
      pembina: 'LLDIKTI IV',
      akreditasi: 'Baik Sekali',
      koordinat: Koordinat(-6.3460, 106.6915),
    ),
  ];

  testWidgets('GrafikDistribusiKampus merender tab Akreditasi & Jenis PT',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buatTema(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: GrafikDistribusiKampus(daftarKampus: contohKampus),
          ),
        ),
      ),
    );

    expect(find.text('Analitik Perguruan Tinggi'), findsOneWidget);
    expect(find.text('Akreditasi'), findsOneWidget);
    expect(find.text('Jenis PT'), findsOneWidget);

    await tester.tap(find.text('Jenis PT'));
    await tester.pumpAndSettle();

    expect(find.textContaining('PTN (2)'), findsOneWidget);
    expect(find.textContaining('PTS (1)'), findsOneWidget);
  });

  testWidgets('GrafikKomparasiWidget merender Radar Chart saat >= 2 kampus',
      (tester) async {
    const item1 = ItemKomparasiKampus(
      idSp: '1',
      kode: '001002',
      nama: 'Universitas Indonesia',
      kelompok: 'PTN',
      pembina: 'Kemdiktisaintek',
      akreditasi: 'Unggul',
      jumlahProdi: 95,
      rasioDosen: '1 : 18',
    );
    const item2 = ItemKomparasiKampus(
      idSp: '2',
      kode: '001001',
      nama: 'Institut Teknologi Bandung',
      kelompok: 'PTN',
      pembina: 'Kemdiktisaintek',
      akreditasi: 'Unggul',
      jumlahProdi: 80,
      rasioDosen: '1 : 15',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buatTema(),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: GrafikKomparasiWidget(daftarKampus: [item1, item2]),
          ),
        ),
      ),
    );

    expect(find.text('Radar Profil Komparasi'), findsOneWidget);
    expect(find.byType(RadarChart), findsOneWidget);
    expect(find.text('Universitas Indonesia'), findsOneWidget);
    expect(find.text('Institut Teknologi Bandung'), findsOneWidget);
  });

  test('hitungKlusterPeta mengelompokkan titik berdekatan pada zoom rendah dan memisahkannya pada zoom tinggi', () {
    final klusterRendah = hitungKlusterPeta(
      daftarKampus: contohKampus,
      zoom: 5.0,
    );
    expect(klusterRendah.length, lessThan(contohKampus.length));

    final klusterTinggi = hitungKlusterPeta(
      daftarKampus: contohKampus,
      zoom: 15.0,
    );
    expect(klusterTinggi.length, contohKampus.length);
    expect(klusterTinggi.every((k) => !k.apakahKluster), isTrue);
  });

  test('hitungKampusTerdekat mengurutkan kampus dari koordinat pengguna terdekat', () {
    // Koordinat sekitar Pamulang (-6.346, 106.691)
    final terdekat = hitungKampusTerdekat(
      daftarKampus: contohKampus,
      lat: -6.346,
      lng: 106.691,
      maks: 3,
    );

    expect(terdekat.length, 3);
    expect(terdekat.first.kampus.kode, '041033'); // Universitas Pamulang paling dekat
    expect(terdekat.last.kampus.kode, '001001'); // ITB paling jauh di daftar
  });

  test('ItemFavorit toRow dan fromRow menjaga integritas data offline', () {
    final awal = ItemFavorit(
      id: 'mhs-123',
      tipe: TipeFavorit.mahasiswa,
      judul: 'Budi Santoso',
      subjudul: '2021001 • Universitas Indonesia',
      metaJson: {
        'id': 'mhs-123',
        'nama': 'Budi Santoso',
        'nim': '2021001',
        'nama_pt': 'Universitas Indonesia',
      },
      createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    );

    final pulih = ItemFavorit.fromRow(awal.toRow());
    expect(pulih.id, awal.id);
    expect(pulih.tipe, TipeFavorit.mahasiswa);
    expect(pulih.judul, 'Budi Santoso');
    expect(pulih.metaJson['nim'], '2021001');
  });
}
