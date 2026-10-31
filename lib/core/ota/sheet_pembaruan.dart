import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/tokens.dart';
import 'layanan_pembaruan.dart';
import 'model_pembaruan.dart';

class SheetPembaruan extends StatefulWidget {
  const SheetPembaruan({
    super.key,
    required this.info,
    required this.versiSaatIni,
    required this.layanan,
  });

  final InfoPembaruan info;
  final String versiSaatIni;
  final LayananPembaruan layanan;

  static Future<void> tampilkan({
    required BuildContext context,
    required InfoPembaruan info,
    required String versiSaatIni,
    required LayananPembaruan layanan,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: !info.pembaruanWajib,
      enableDrag: !info.pembaruanWajib,
      builder: (context) => SheetPembaruan(
        info: info,
        versiSaatIni: versiSaatIni,
        layanan: layanan,
      ),
    );
  }

  @override
  State<SheetPembaruan> createState() => _SheetPembaruanState();
}

class _SheetPembaruanState extends State<SheetPembaruan> {
  bool _sedangMengunduh = false;
  double _progres = 0.0;
  String _infoProgres = '';
  String? _galat;
  CancelToken? _cancelToken;

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<void> _mulaiUnduhDanPasang() async {
    setState(() {
      _sedangMengunduh = true;
      _progres = 0.0;
      _infoProgres = 'Memulai unduhan...';
      _galat = null;
    });

    _cancelToken = CancelToken();

    try {
      await widget.layanan.unduhDanPasangApk(
        url: widget.info.tautanUnduh,
        sha256Expected: widget.info.sha256,
        cancelToken: _cancelToken,
        onProgress: (persen, diterima, total) {
          if (!mounted) return;
          setState(() {
            _progres = persen >= 0 ? persen : 0.0;
            if (total > 0) {
              final recMb = (diterima / (1024 * 1024)).toStringAsFixed(1);
              final totMb = (total / (1024 * 1024)).toStringAsFixed(1);
              final pct = (_progres * 100).toInt();
              _infoProgres = 'Mengunduh: $pct% ($recMb / $totMb MB)';
            } else {
              final recMb = (diterima / (1024 * 1024)).toStringAsFixed(1);
              _infoProgres = 'Mengunduh: $recMb MB...';
            }
          });
        },
      );

      if (mounted) {
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sedangMengunduh = false;
        _galat = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;

    return Container(
      decoration: const BoxDecoration(
        color: Warna.tinta,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          top: BorderSide(color: Warna.kunyit, width: 2),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Baris Judul & Ikon
            Row(
              children: [
                const Icon(PhosphorIconsFill.arrowCircleUp, color: Warna.kunyit, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pembaruan Tersedia',
                    style: Gaya.judulLayar.copyWith(fontSize: 18),
                  ),
                ),
                if (!info.pembaruanWajib && !_sedangMengunduh)
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.x, color: Warna.kapurRedup),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Versi badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Warna.tintaAngkat,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Warna.garis),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Versi saat ini: v${widget.versiSaatIni}',
                    style: Gaya.catatan.copyWith(color: Warna.kapurRedup),
                  ),
                  Text(
                    'Versi baru: v${info.versi}',
                    style: Gaya.catatan.copyWith(
                      color: Warna.kunyit,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Catatan Rilis / Changelog
            if (info.catatanRilis.isNotEmpty) ...[
              Text(
                'Catatan Rilis:'.toUpperCase(),
                style: const TextStyle(
                  color: Warna.kapurRedup,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 140),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Warna.tintaAngkat,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Warna.garis),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: info.catatanRilis.map((catatan) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '• ',
                              style: TextStyle(color: Warna.kunyit, fontWeight: FontWeight.bold),
                            ),
                            Expanded(
                              child: Text(
                                catatan,
                                style: const TextStyle(color: Warna.kapur, fontSize: 13, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Pesan Galat bila ada
            if (_galat != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Warna.karang.withValues(alpha: 0.15),
                  border: Border.all(color: Warna.karang, width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _galat!,
                  style: const TextStyle(color: Warna.karang, fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Indikator Progres Unduhan
            if (_sedangMengunduh) ...[
              LinearProgressIndicator(
                value: _progres > 0 ? _progres : null,
                color: Warna.kunyit,
                backgroundColor: Warna.garis,
                minHeight: 6,
              ),
              const SizedBox(height: 8),
              Text(
                _infoProgres,
                style: Gaya.catatan.copyWith(color: Warna.kapurRedup),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],

            // Tombol Aksi
            if (!_sedangMengunduh)
              FilledButton(
                onPressed: _mulaiUnduhDanPasang,
                style: FilledButton.styleFrom(
                  backgroundColor: Warna.kunyit,
                  foregroundColor: Warna.tinta,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Unduh & Pasang Pembaruan',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
