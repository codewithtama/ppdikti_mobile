import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/tokens.dart';
import '../../data/model/pencarian_global.dart';
import 'kartu_digital_widget.dart';

class KartuDigitalSheet extends StatefulWidget {
  const KartuDigitalSheet({
    super.key,
    this.mahasiswa,
    this.dosen,
  }) : assert(mahasiswa != null || dosen != null, 'Mahasiswa atau Dosen wajib ada');

  final DetailMahasiswa? mahasiswa;
  final DetailDosen? dosen;

  static Future<void> tampilkan(
    BuildContext context, {
    DetailMahasiswa? mahasiswa,
    DetailDosen? dosen,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => KartuDigitalSheet(
        mahasiswa: mahasiswa,
        dosen: dosen,
      ),
    );
  }

  @override
  State<KartuDigitalSheet> createState() => _KartuDigitalSheetState();
}

class _KartuDigitalSheetState extends State<KartuDigitalSheet> {
  final GlobalKey _kartuKey = GlobalKey();
  bool _sisiBelakang = false;
  bool _sedangMemproses = false;

  String get _namaFileClean {
    final raw = widget.mahasiswa?.ringkasan.nama ?? widget.dosen?.ringkasan.nama ?? 'identitas';
    final clean = raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    return 'kartu_pddikti_$clean.png';
  }

  Future<File?> _hasilkanFileGambar() async {
    try {
      final boundary =
          _kartuKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$_namaFileClean');
      await file.writeAsBytes(pngBytes);
      return file;
    } catch (_) {
      return null;
    }
  }

  Future<void> _bagikanGambar() async {
    setState(() => _sedangMemproses = true);
    try {
      final file = await _hasilkanFileGambar();
      if (!mounted) return;

      if (file != null) {
        final nama = widget.mahasiswa?.ringkasan.nama ?? widget.dosen?.ringkasan.nama ?? '';
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: 'image/png')],
            text: 'Kartu Identitas Digital Resmi PDDikti: $nama\nTerverifikasi Pangkalan Data Pendidikan Tinggi Kemdiktisaintek RI',
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuat gambar kartu')),
        );
      }
    } finally {
      if (mounted) setState(() => _sedangMemproses = false);
    }
  }

  Future<void> _bukaFileGambar() async {
    setState(() => _sedangMemproses = true);
    try {
      final file = await _hasilkanFileGambar();
      if (!mounted) return;

      if (file != null) {
        await OpenFilex.open(file.path);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka gambar kartu')),
        );
      }
    } finally {
      if (mounted) setState(() => _sedangMemproses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final judul = widget.mahasiswa != null
        ? 'Kartu Digital Mahasiswa'
        : 'Kartu Digital Dosen';

    return Container(
      decoration: const BoxDecoration(
        color: Warna.tinta,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: Warna.garis, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Warna.garisTegas,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                judul,
                style: const TextStyle(
                  color: Warna.kapur,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: const Icon(PhosphorIconsRegular.x, size: 20, color: Warna.kapurRedup),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Render Area Kartu Digital (dengan RepaintBoundary untuk Export Gambar)
          RepaintBoundary(
            key: _kartuKey,
            child: KartuDigitalWidget(
              mahasiswa: widget.mahasiswa,
              dosen: widget.dosen,
              tampilkanSisiBelakang: _sisiBelakang,
            ),
          ),
          const SizedBox(height: 16),

          // Tombol Balik Kartu
          OutlinedButton.icon(
            onPressed: () {
              setState(() => _sisiBelakang = !_sisiBelakang);
            },
            icon: const Icon(PhosphorIconsRegular.arrowsClockwise, size: 16),
            label: Text(_sisiBelakang ? 'Lihat Sisi Depan' : 'Lihat Sisi Belakang (QR Code)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Warna.kunyit,
              side: const BorderSide(color: Warna.kunyit, width: 1),
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(height: 20),

          // Tombol Aksi Simpan & Bagikan
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _sedangMemproses ? null : _bagikanGambar,
                  icon: _sedangMemproses
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Warna.tinta),
                        )
                      : const Icon(PhosphorIconsRegular.shareNetwork, size: 18),
                  label: const Text('Bagikan Kartu (PNG)'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Warna.kunyit,
                    foregroundColor: Warna.tinta,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _sedangMemproses ? null : _bukaFileGambar,
                icon: const Icon(PhosphorIconsRegular.image, size: 18),
                label: const Text('Buka'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Warna.kapur,
                  side: const BorderSide(color: Warna.garisTegas),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
