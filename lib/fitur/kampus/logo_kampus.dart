import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

class LogoKampus extends StatelessWidget {
  const LogoKampus({
    super.key,
    required this.idSp,
    required this.nama,
    this.ukuran = 40.0,
  });

  final String idSp;
  final String nama;
  final double ukuran;

  static const _jenisInstitusi = {
    'universitas',
    'institut',
    'sekolah',
    'tinggi',
    'politeknik',
    'akademi',
    'akademik',
  };

  /// Hitung 1 atau 2 huruf monogram sesuai aturan Section 8.4
  static String hitungMonogram(String namaKampus) {
    final kata = namaKampus
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((k) => k.isNotEmpty)
        .toList();

    final kataBukanJenis = kata
        .where((k) => !_jenisInstitusi.contains(k.toLowerCase()))
        .toList();

    if (kataBukanJenis.isNotEmpty) {
      if (kataBukanJenis.length >= 2) {
        return '${kataBukanJenis[0][0]}${kataBukanJenis[1][0]}'.toUpperCase();
      }
      return kataBukanJenis[0][0].toUpperCase();
    }

    if (kata.isNotEmpty && kata[0].isNotEmpty) {
      return kata[0][0].toUpperCase();
    }

    return 'K';
  }

  @override
  Widget build(BuildContext context) {
    final monogram = hitungMonogram(nama);
    final fallback = Container(
      width: ukuran,
      height: ukuran,
      color: Warna.tintaAngkat,
      alignment: Alignment.center,
      child: Text(
        monogram,
        style: Gaya.tombol.copyWith(
          fontSize: ukuran * 0.42,
          fontWeight: FontWeight.w600,
          color: Warna.kapur,
        ),
      ),
    );

    if (idSp.isEmpty) {
      return fallback;
    }

    final encodedId = Uri.encodeComponent(idSp);
    final url = 'https://pddikti.kemdiktisaintek.go.id/api/pt/logo/$encodedId';

    return SizedBox(
      width: ukuran,
      height: ukuran,
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (context, url) => fallback,
        errorWidget: (context, url, error) => fallback,
      ),
    );
  }
}

