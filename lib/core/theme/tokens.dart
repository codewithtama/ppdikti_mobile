import 'package:flutter/material.dart';

abstract final class Warna {
  static const tinta = Color(0xFF1A1F33);
  static const tintaAngkat = Color(0xFF242A44);
  static const garis = Color(0xFF3A4266);
  static const garisTegas = Color(0xFF6F79A3);
  static const kapur = Color(0xFFECE7DA);
  static const kapurRedup = Color(0xFFA9AEC4);
  static const kunyit = Color(0xFFF0B429);
  static const laut = Color(0xFF5CC8B8);
  static const karang = Color(0xFFE8826B);

  static Color get titikBiasa => kapur.withValues(alpha: 0.38);
  static Color get titikRedup => kapur.withValues(alpha: 0.18);
}

abstract final class Jarak {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
}

abstract final class Gaya {
  static TextStyle _archivo(
    double ukuran,
    double tinggiBaris,
    int bobot, {
    double lebar = 100,
    bool tabular = false,
    Color warna = Warna.kapur,
  }) =>
      TextStyle(
        fontFamily: 'Archivo',
        fontSize: ukuran,
        height: tinggiBaris / ukuran,
        fontWeight: FontWeight.values[(bobot ~/ 100) - 1],
        fontVariations: [
          FontVariation('wght', bobot.toDouble()),
          FontVariation('wdth', lebar),
        ],
        fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
        letterSpacing: 0,
        color: warna,
      );

  static final judulLayar = _archivo(24, 30, 600);
  static final namaDetail = _archivo(22, 28, 600, lebar: 87);
  static final namaBaris = _archivo(16, 21, 600, lebar: 90);
  static final isi = _archivo(15, 22, 400);
  static final tombol = _archivo(15, 20, 600);
  static final label = _archivo(13, 18, 500, warna: Warna.kapurRedup);
  static final angka = _archivo(17, 22, 500, tabular: true);
  static final catatan = _archivo(12, 16, 400, warna: Warna.kapurRedup);

  static const bacaan = TextStyle(
    fontFamily: 'SourceSerif4',
    fontSize: 16,
    height: 26 / 16,
    color: Warna.kapur,
  );
}
