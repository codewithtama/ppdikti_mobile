import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show PointMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';

/// Provider memuat dan meng-cache Path siluet kepulauan Indonesia
final petaIndonesiaPathProvider = FutureProvider<Path>((ref) async {
  final jsonStr = await rootBundle.loadString('assets/data/peta_indonesia.json');
  final dynamic decoded = jsonDecode(jsonStr);
  final path = Path();
  if (decoded is List) {
    for (final ringItem in decoded) {
      if (ringItem is List && ringItem.length >= 4) {
        final firstX = (ringItem[0] as num).toDouble();
        final firstY = (ringItem[1] as num).toDouble();
        path.moveTo(firstX, firstY);
        for (int i = 2; i < ringItem.length; i += 2) {
          final px = (ringItem[i] as num).toDouble();
          final py = (ringItem[i + 1] as num).toDouble();
          path.lineTo(px, py);
        }
        path.close();
      }
    }
  }
  return path;
});

class PetaTitikPainter extends CustomPainter {
  PetaTitikPainter({
    this.pathIndonesia,
    required this.redup,
    required this.sorot,
    required this.kontrol,
    required this.sapuan,
    required this.adaFilter,
    this.cincinTunggal,
  }) : super(repaint: Listenable.merge([kontrol, sapuan]));

  /// Siluet kepulauan wilayah Indonesia (basemap)
  final Path? pathIndonesia;

  /// Koordinat ternormalisasi (x 0..1, y 0..0,383), urut dari barat ke timur.
  final Float32List redup;
  final Float32List sorot;
  final TransformationController kontrol;
  final Animation<double> sapuan; // 0..1
  final bool adaFilter;
  final Offset? cincinTunggal;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    canvas.save();
    canvas.clipRect(Offset.zero & size);

    final m = kontrol.value;
    final skala = m.getMaxScaleOnAxis();
    canvas.transform(m.storage);
    canvas.scale(size.width); // ruang kerja: lebar = 1

    // 1. Gambar Siluet Kepulauan Indonesia (Basemap)
    if (pathIndonesia != null) {
      final fillPaint = Paint()
        ..color = Warna.tintaAngkat
        ..style = PaintingStyle.fill;
      canvas.drawPath(pathIndonesia!, fillPaint);

      final strokePaint = Paint()
        ..color = Warna.garis
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6 / (size.width * skala);
      canvas.drawPath(pathIndonesia!, strokePaint);
    }

    // 2. Gambar Titik-titik Kampus
    final diameter =
        (1.8 * math.sqrt(skala)).clamp(1.8, 6.0) / (size.width * skala);

    final cat = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = diameter
      ..color = adaFilter ? Warna.titikRedup : Warna.titikBiasa;

    final totalPoints = redup.length ~/ 2;
    final n = (totalPoints * sapuan.value).floor() * 2;
    if (n > 0) {
      canvas.drawRawPoints(
        PointMode.points,
        Float32List.sublistView(redup, 0, n),
        cat,
      );
    }

    if (sorot.isNotEmpty) {
      cat
        ..color = Warna.kunyit
        ..strokeWidth = diameter * 1.4;
      canvas.drawRawPoints(PointMode.points, sorot, cat);
    }

    if (cincinTunggal != null) {
      final ringPaint = Paint()
        ..color = Warna.kunyit
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 / (size.width * skala);
      final radius = (diameter * 2.2);
      canvas.drawCircle(cincinTunggal!, radius, ringPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(PetaTitikPainter old) =>
      old.pathIndonesia != pathIndonesia ||
      old.redup != redup ||
      old.sorot != sorot ||
      old.adaFilter != adaFilter ||
      old.cincinTunggal != cincinTunggal;
}

