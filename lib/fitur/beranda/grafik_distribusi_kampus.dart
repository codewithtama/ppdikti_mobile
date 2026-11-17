import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/format/angka.dart';
import '../../core/theme/tokens.dart';
import '../../data/model/kampus.dart';

/// Visualisasi interaktif distribusi 4.342 perguruan tinggi di Beranda
/// menggunakan fl_chart (Donut Akreditasi & Bar Jenis PT).
class GrafikDistribusiKampus extends StatefulWidget {
  const GrafikDistribusiKampus({super.key, required this.daftarKampus});

  final List<Kampus> daftarKampus;

  @override
  State<GrafikDistribusiKampus> createState() => _GrafikDistribusiKampusState();
}

class _GrafikDistribusiKampusState extends State<GrafikDistribusiKampus> {
  int _tabIndex = 0; // 0 = Akreditasi, 1 = Jenis PT
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.daftarKampus.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Warna.tintaAngkat,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Warna.garis, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Analitik Perguruan Tinggi',
                      style: TextStyle(
                        color: Warna.kapur,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${FormatAngka.ribuan(widget.daftarKampus.length)} kampus terdaftar nasional',
                      style: Gaya.catatan,
                    ),
                  ],
                ),
              ),
              _buildTabToggle(),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _tabIndex == 0
                ? _buildAkreditasiChart()
                : _buildJenisPtChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Warna.tinta,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Warna.garis, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TabTombol(
            label: 'Akreditasi',
            aktif: _tabIndex == 0,
            onTap: () => setState(() => _tabIndex = 0),
          ),
          _TabTombol(
            label: 'Jenis PT',
            aktif: _tabIndex == 1,
            onTap: () => setState(() => _tabIndex = 1),
          ),
        ],
      ),
    );
  }

  Widget _buildAkreditasiChart() {
    int unggul = 0;
    int baikSekali = 0;
    int baik = 0;
    int lainnya = 0;

    for (final k in widget.daftarKampus) {
      final ak = k.akreditasi.toLowerCase().trim();
      if (ak == 'unggul' || ak == 'a') {
        unggul++;
      } else if (ak == 'baik sekali' || ak == 'b') {
        baikSekali++;
      } else if (ak == 'baik' || ak == 'c') {
        baik++;
      } else {
        lainnya++;
      }
    }

    final total = widget.daftarKampus.length;
    final items = [
      (label: 'Unggul / A', jumlah: unggul, warna: Warna.kunyit),
      (label: 'Baik Sekali / B', jumlah: baikSekali, warna: Warna.laut),
      (label: 'Baik / C', jumlah: baik, warna: const Color(0xFF60A5FA)),
      (label: 'Belum / Lainnya', jumlah: lainnya, warna: Warna.garisTegas),
    ];

    return Row(
      key: const ValueKey('akreditasi_chart'),
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.touchedSection == null) {
                      _touchedPieIndex = -1;
                      return;
                    }
                    _touchedPieIndex =
                        response.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 34,
              sections: List.generate(items.length, (i) {
                final isTouched = i == _touchedPieIndex;
                final item = items[i];
                final pct = total > 0 ? (item.jumlah * 100 / total) : 0.0;
                return PieChartSectionData(
                  color: item.warna,
                  value: item.jumlah.toDouble(),
                  title: pct >= 7 ? '${pct.toStringAsFixed(0)}%' : '',
                  radius: isTouched ? 42 : 35,
                  titleStyle: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: i == 3 ? Warna.kapur : Warna.tinta,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(items.length, (i) {
              final item = items[i];
              final pct = total > 0 ? (item.jumlah * 100 / total) : 0.0;
              final highlight = i == _touchedPieIndex;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: item.warna,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: highlight ? Warna.kunyit : Warna.kapur,
                          fontSize: 12,
                          fontWeight:
                              highlight ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '${FormatAngka.ribuan(item.jumlah)} (${pct.toStringAsFixed(1)}%)',
                      style: Gaya.angka.copyWith(
                        fontSize: 11,
                        color: Warna.kapurRedup,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildJenisPtChart() {
    int ptn = 0;
    int pts = 0;
    int ptkl = 0;
    int pta = 0;

    for (final k in widget.daftarKampus) {
      switch (k.kelompok.toUpperCase().trim()) {
        case 'PTN':
          ptn++;
        case 'PTS':
          pts++;
        case 'PTKL':
          ptkl++;
        case 'PTA':
          pta++;
      }
    }

    final data = [
      (label: 'PTN', jumlah: ptn, warna: Warna.kunyit),
      (label: 'PTS', jumlah: pts, warna: Warna.laut),
      (label: 'PTKL', jumlah: ptkl, warna: const Color(0xFF60A5FA)),
      (label: 'PTA', jumlah: pta, warna: const Color(0xFFF59E0B)),
    ];
    final maxVal = data.fold<int>(1, (m, e) => e.jumlah > m ? e.jumlah : m);

    return SizedBox(
      key: const ValueKey('jenis_pt_chart'),
      height: 155,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.18,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Warna.tinta,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final item = data[group.x.toInt()];
                return BarTooltipItem(
                  '${item.label}\n${FormatAngka.ribuan(item.jumlah)} PT',
                  const TextStyle(
                    color: Warna.kapur,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) {
                    return const SizedBox.shrink();
                  }
                  final item = data[idx];
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${item.label} (${FormatAngka.ribuan(item.jumlah)})',
                      style: const TextStyle(
                        color: Warna.kapurRedup,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: Warna.garis, strokeWidth: 0.7),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(data.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[i].jumlah.toDouble(),
                  color: data[i].warna,
                  width: 28,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(3),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _TabTombol extends StatelessWidget {
  const _TabTombol({
    required this.label,
    required this.aktif,
    required this.onTap,
  });

  final String label;
  final bool aktif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: aktif ? Warna.kunyit : Colors.transparent,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: aktif ? Warna.tinta : Warna.kapurRedup,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
