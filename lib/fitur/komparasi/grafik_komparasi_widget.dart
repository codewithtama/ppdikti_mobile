import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import 'komparasi_model.dart';

/// Visualisasi Radar Chart untuk membandingkan hingga 3 perguruan tinggi
/// berdasarkan Akreditasi, Skala Prodi, Rasio Dosen:Mhs, dan Status Aktif.
class GrafikKomparasiWidget extends StatelessWidget {
  const GrafikKomparasiWidget({super.key, required this.daftarKampus});

  final List<ItemKomparasiKampus> daftarKampus;

  static const List<Color> _palet = [
    Warna.kunyit,
    Warna.laut,
    Color(0xFF60A5FA),
  ];

  double _skorAkreditasi(String ak) {
    final lower = ak.toLowerCase().trim();
    if (lower == 'unggul' || lower == 'a') return 100;
    if (lower == 'baik sekali' || lower == 'b') return 82;
    if (lower == 'baik' || lower == 'c') return 65;
    if (lower.contains('tidak') || lower == '-' || lower.isEmpty) return 30;
    return 50;
  }

  double _skorProdi(int? jumlah) {
    if (jumlah == null || jumlah <= 0) return 25;
    if (jumlah >= 100) return 100;
    return (25 + (jumlah * 0.75)).clamp(25, 100).toDouble();
  }

  double _skorRasio(String? rasio) {
    if (rasio == null || !rasio.contains(':')) return 40;
    final parts = rasio.split(':');
    if (parts.length < 2) return 40;
    final mhsPerDosen = double.tryParse(
          parts[1].replaceAll(RegExp(r'[^0-9.]'), ''),
        ) ??
        30;
    if (mhsPerDosen <= 0) return 40;
    // Rasio ideal 1:10..1:25 mendapat skor tinggi, >1:50 lebih rendah
    if (mhsPerDosen <= 20) return 95;
    if (mhsPerDosen <= 30) return 80;
    if (mhsPerDosen <= 45) return 60;
    return 40;
  }

  double _skorStatus(String status) {
    final s = status.toLowerCase().trim();
    if (s == 'aktif') return 100;
    if (s.contains('alih') || s.contains('pembinaan')) return 55;
    return 30;
  }

  @override
  Widget build(BuildContext context) {
    if (daftarKampus.length < 2) return const SizedBox.shrink();

    const sumbu = ['Akreditasi', 'Skala Prodi', 'Rasio Ideal', 'Keaktifan'];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Warna.tintaAngkat,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Warna.garis, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Radar Profil Komparasi',
            style: TextStyle(
              color: Warna.kapur,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: List.generate(daftarKampus.length, (i) {
              final k = daftarKampus[i];
              final warna = _palet[i % _palet.length];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: warna,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(
                      k.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Warna.kapurRedup,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                tickCount: 4,
                ticksTextStyle: const TextStyle(
                  color: Colors.transparent,
                  fontSize: 8,
                ),
                radarBorderData: const BorderSide(color: Warna.garisTegas, width: 1),
                gridBorderData: const BorderSide(color: Warna.garis, width: 0.8),
                tickBorderData: const BorderSide(color: Warna.garis, width: 0.8),
                titlePositionPercentageOffset: 0.16,
                titleTextStyle: const TextStyle(
                  color: Warna.kapur,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                getTitle: (index, angle) => RadarChartTitle(
                  text: sumbu[index],
                ),
                dataSets: List.generate(daftarKampus.length, (i) {
                  final k = daftarKampus[i];
                  final warna = _palet[i % _palet.length];
                  return RadarDataSet(
                    fillColor: warna.withValues(alpha: 0.18),
                    borderColor: warna,
                    borderWidth: 2,
                    entryRadius: 3,
                    dataEntries: [
                      RadarEntry(value: _skorAkreditasi(k.akreditasi)),
                      RadarEntry(value: _skorProdi(k.jumlahProdi)),
                      RadarEntry(value: _skorRasio(k.rasioDosen)),
                      RadarEntry(value: _skorStatus(k.status)),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
