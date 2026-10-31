import '../../../data/model/kampus.dart';

class TitikTerproyeksi {
  const TitikTerproyeksi({
    required this.kampus,
    required this.x,
    required this.y,
  });

  final Kampus kampus;
  final double x; // 0..1
  final double y; // 0..0.383
}

class GridKetuk {
  GridKetuk(this.semuaTitik) {
    _bangunGrid();
  }

  final List<TitikTerproyeksi> semuaTitik;
  static const double ukuranSel = 0.01;
  final Map<int, List<TitikTerproyeksi>> _selMap = {};

  int _kunciSel(int ix, int iy) => (ix << 16) | (iy & 0xFFFF);

  void _bangunGrid() {
    for (final t in semuaTitik) {
      final ix = (t.x / ukuranSel).floor();
      final iy = (t.y / ukuranSel).floor();
      final kunci = _kunciSel(ix, iy);
      (_selMap[kunci] ??= []).add(t);
    }
  }

  /// Mencari kampus dalam radius ambang normalisasi (ambangDp / (sizeWidth * skala))
  List<Kampus> cariKampusDekat({
    required double normX,
    required double normY,
    required double radiusNorm,
    int maks = 8,
  }) {
    final minIx = ((normX - radiusNorm) / ukuranSel).floor();
    final maxIx = ((normX + radiusNorm) / ukuranSel).floor();
    final minIy = ((normY - radiusNorm) / ukuranSel).floor();
    final maxIy = ((normY + radiusNorm) / ukuranSel).floor();

    final kandidat = <({Kampus kampus, double jarakKuadrat})>[];
    final radiusSq = radiusNorm * radiusNorm;

    for (int ix = minIx; ix <= maxIx; ix++) {
      for (int iy = minIy; iy <= maxIy; iy++) {
        final list = _selMap[_kunciSel(ix, iy)];
        if (list == null) continue;

        for (final t in list) {
          final dx = t.x - normX;
          final dy = t.y - normY;
          final distSq = dx * dx + dy * dy;
          if (distSq <= radiusSq) {
            kandidat.add((kampus: t.kampus, jarakKuadrat: distSq));
          }
        }
      }
    }

    kandidat.sort((a, b) => a.jarakKuadrat.compareTo(b.jarakKuadrat));
    return kandidat.take(maks).map((e) => e.kampus).toList();
  }

  /// Menghitung proyeksi equirectangular (ruang kerja 1 x 0.383):
  /// x = (bujur - 94.5) / 47, y = (6.5 - lintang) / 47
  static ({double x, double y}) proyeksikan(double lintang, double bujur) {
    final x = (bujur - 94.5) / 47.0;
    final y = (6.5 - lintang) / 47.0;
    return (x: x, y: y);
  }
}
