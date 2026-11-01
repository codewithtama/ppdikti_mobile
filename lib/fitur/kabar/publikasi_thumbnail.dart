import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/tokens.dart';
import '../../data/model/publikasi.dart';

class PublikasiThumbnail extends StatelessWidget {
  const PublikasiThumbnail({
    super.key,
    required this.publikasi,
    this.lebar = 80,
    this.tinggi = 100,
  });

  final Publikasi publikasi;
  final double lebar;
  final double tinggi;

  static const Map<String, String> _headers = {
    'Origin': 'https://pddikti.kemdiktisaintek.go.id',
    'Referer': 'https://pddikti.kemdiktisaintek.go.id/',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
    'X-User-IP': '103.47.132.29',
  };

  /// Ekstraksi tahun dari judul publikasi (contoh: "Tahun 2025" -> "2025")
  String _ekstrakTahun() {
    final match = RegExp(r'20\d{2}').firstMatch(publikasi.judul);
    if (match != null) return match.group(0)!;
    final matchCreated = RegExp(r'20\d{2}').firstMatch(publikasi.dibuatPada);
    if (matchCreated != null) return matchCreated.group(0)!;
    return '2025';
  }

  /// Pemilihan warna gradien sampul buku sesuai tahun edisi
  List<Color> _pilihGradien(String tahun) {
    switch (tahun) {
      case '2026':
      case '2025':
        // Royal Blue seperti screenshot Buku Statistik 2025
        return const [Color(0xFF1E6FD9), Color(0xFF0C46A2)];
      case '2024':
        // Deep Violet/Purple seperti screenshot Buku Statistik 2024
        return const [Color(0xFF6B3BA7), Color(0xFF4C2188)];
      case '2023':
        // Emerald / Teal
        return const [Color(0xFF16806E), Color(0xFF0F5247)];
      case '2022':
        // Amber Coral
        return const [Color(0xFFD97706), Color(0xFFB45309)];
      default:
        // Dark Indigo / Slate
        return const [Color(0xFF2E3A59), Color(0xFF1A2238)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final tahun = _ekstrakTahun();
    final gradien = _pilihGradien(tahun);

    // Widget sampul buku digital bergaya persis seperti desain web resmi PDDikti
    final sampulBukuWidget = Container(
      width: lebar,
      height: tinggi,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradien,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Efek lipatan punggung buku (spine) di sisi kiri
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 5,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
                color: Colors.black.withValues(alpha: 0.25),
              ),
            ),
          ),

          // Pola aksen latar belakang
          Positioned(
            right: -8,
            bottom: -8,
            child: Icon(
              PhosphorIconsFill.student,
              size: 42,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),

          // Teks Tipografi Sampul Buku
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buku Statistik',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Pendidikan\nTinggi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tahun,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Higher Education Statistic',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 5.5,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final rawThumb = publikasi.thumbnail?.trim();
    if (rawThumb == null || rawThumb.isEmpty) {
      return sampulBukuWidget;
    }

    String thumbUrl = rawThumb;
    if (!thumbUrl.startsWith('http')) {
      thumbUrl = 'https://api-pddikti.kemdiktisaintek.go.id$thumbUrl';
    }

    return Container(
      width: lebar,
      height: tinggi,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Warna.tintaAngkat,
      ),
      clipBehavior: Clip.antiAlias,
      child: CachedNetworkImage(
        imageUrl: thumbUrl,
        httpHeaders: _headers,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 150),
        fadeOutDuration: Duration.zero,
        placeholder: (context, url) => sampulBukuWidget,
        errorWidget: (context, url, error) => sampulBukuWidget,
      ),
    );
  }
}

