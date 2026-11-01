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

  static const Map<String, String> _headersLogo = {
    'Origin': 'https://pddikti.kemdiktisaintek.go.id',
    'Referer': 'https://pddikti.kemdiktisaintek.go.id/',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
    'X-User-IP': '103.47.132.29',
  };

  @override
  Widget build(BuildContext context) {
    final monogram = hitungMonogram(nama);
    final fallback = Container(
      width: ukuran,
      height: ukuran,
      decoration: BoxDecoration(
        color: Warna.tintaAngkat,
        shape: BoxShape.circle,
        border: Border.all(color: Warna.garis, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        monogram,
        style: Gaya.tombol.copyWith(
          fontSize: ukuran * 0.38,
          fontWeight: FontWeight.w700,
          color: Warna.kunyit,
        ),
      ),
    );

    if (idSp.trim().isEmpty) {
      return fallback;
    }

    final encodedId = Uri.encodeComponent(idSp.trim());
    final url = 'https://api-pddikti.kemdiktisaintek.go.id/pt/logo/$encodedId';

    return Container(
      width: ukuran,
      height: ukuran,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Warna.garis, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(ukuran * 0.08),
        child: CachedNetworkImage(
          imageUrl: url,
          httpHeaders: _headersLogo,
          fit: BoxFit.contain,
          fadeInDuration: const Duration(milliseconds: 150),
          fadeOutDuration: Duration.zero,
          placeholder: (context, url) => fallback,
          errorWidget: (context, url, error) => fallback,
        ),
      ),
    );
  }
}

