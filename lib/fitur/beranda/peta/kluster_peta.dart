import 'dart:math' as math;
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../data/model/kampus.dart';

class KlusterKampus {
  const KlusterKampus({
    required this.pusat,
    required this.daftar,
  });

  final LatLng pusat;
  final List<Kampus> daftar;

  bool get apakahKluster => daftar.length > 1;
  int get jumlah => daftar.length;
  Kampus get utama => daftar.first;
}

/// Mengelompokkan marker kampus ke dalam grid spasial berdasarkan level zoom.
/// Ketika zoom >= 13.5, seluruh titik dalam viewport ditampilkan terpisah.
List<KlusterKampus> hitungKlusterPeta({
  required List<Kampus> daftarKampus,
  required double zoom,
  LatLngBounds? bounds,
}) {
  if (daftarKampus.isEmpty) return const [];

  final tanpaKluster = zoom >= 13.5;
  final cellDeg = tanpaKluster ? 0.0 : (360.0 / math.pow(2.0, zoom)) * 0.28;

  if (tanpaKluster || cellDeg <= 0) {
    final hasil = <KlusterKampus>[];
    for (final k in daftarKampus) {
      final kor = k.koordinat;
      if (kor == null) continue;
      final pt = LatLng(kor.lintang, kor.bujur);
      if (bounds != null && !bounds.contains(pt)) continue;
      hasil.add(KlusterKampus(pusat: pt, daftar: [k]));
    }
    return hasil;
  }

  final buckets = <String, List<Kampus>>{};
  for (final k in daftarKampus) {
    final kor = k.koordinat;
    if (kor == null) continue;
    final pt = LatLng(kor.lintang, kor.bujur);
    if (bounds != null && !bounds.contains(pt)) continue;

    final gx = (kor.bujur / cellDeg).floor();
    final gy = (kor.lintang / cellDeg).floor();
    final key = '$gx:$gy';
    (buckets[key] ??= []).add(k);
  }

  final hasil = <KlusterKampus>[];
  for (final group in buckets.values) {
    double sumLat = 0;
    double sumLng = 0;
    for (final k in group) {
      final kor = k.koordinat!;
      sumLat += kor.lintang;
      sumLng += kor.bujur;
    }
    hasil.add(
      KlusterKampus(
        pusat: LatLng(sumLat / group.length, sumLng / group.length),
        daftar: group,
      ),
    );
  }
  return hasil;
}

/// Menghitung N kampus terdekat dari koordinat pengguna menggunakan rumus geodesik Geolocator.
List<({Kampus kampus, double jarakMeter})> hitungKampusTerdekat({
  required List<Kampus> daftarKampus,
  required double lat,
  required double lng,
  int maks = 15,
}) {
  final daftar = <({Kampus kampus, double jarakMeter})>[];
  for (final k in daftarKampus) {
    final kor = k.koordinat;
    if (kor == null) continue;
    final jarak = Geolocator.distanceBetween(
      lat,
      lng,
      kor.lintang,
      kor.bujur,
    );
    daftar.add((kampus: k, jarakMeter: jarak));
  }

  daftar.sort((a, b) => a.jarakMeter.compareTo(b.jarakMeter));
  if (daftar.length > maks) {
    return daftar.sublist(0, maks);
  }
  return daftar;
}
