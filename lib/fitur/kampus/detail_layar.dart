import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/format/angka.dart';
import '../../core/theme/tokens.dart';
import '../beranda/ledger.dart';
import '../beranda/peta/grid_ketuk.dart';
import '../beranda/peta/peta_painter.dart';
import 'detail_vm.dart';
import 'kampus_vm.dart';
import 'logo_kampus.dart';

class DetailKampusLayar extends ConsumerWidget {
  const DetailKampusLayar({super.key, required this.kode});
  final String kode;

  void _tampilkanInfoKelulusan(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tentang tingkat kelulusan', style: Gaya.judulLayar.copyWith(fontSize: 18)),
              const SizedBox(height: 12),
              Text(
                'Angka dari PDDikti. Periode dan cara menghitungnya tidak dijelaskan di API, jadi jangan dipakai untuk membandingkan kampus.',
                style: Gaya.isi,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Mengerti'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _bukaPeta(double lintang, double bujur, String nama) async {
    final uri = Uri.parse('geo:$lintang,$bujur?q=$lintang,$bujur($nama)');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lintang,$bujur');
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kampus = ref.watch(detailKampusProvider(kode));
    final kelulusanAsync = ref.watch(kelulusanProvider(kode));
    final dataParsed = ref.watch(daftarKampusProvider).value;
    final pathIndonesiaAsync = ref.watch(petaIndonesiaPathProvider);

    if (kampus == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text('Kampus tidak ditemukan.', style: Gaya.isi),
        ),
      );
    }

    final k = kampus.koordinat;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Kampus'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          // Header: Logo 56dp & Nama Kampus
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LogoKampus(
                idSp: kampus.idSp,
                nama: kampus.nama,
                ukuran: 56,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kampus.nama,
                      style: Gaya.namaDetail,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kode PT ${kampus.kode}',
                      style: Gaya.label.copyWith(color: Warna.kunyit),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Ledger Informasi Umum
          LedgerWidget(
            items: [
              ItemLedger(label: 'Kelompok', nilai: kampus.kelompok),
              ItemLedger(label: 'Pembina', nilai: kampus.pembina),
              ItemLedger(
                label: 'Kota atau kabupaten',
                nilai: kampus.kota ?? 'Kota belum diisi',
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Bagian Tingkat Kelulusan
          Row(
            children: [
              Text('Tingkat kelulusan', style: Gaya.judulLayar.copyWith(fontSize: 18)),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.info_outline, size: 18, color: Warna.kapurRedup),
                tooltip: 'Info tingkat kelulusan',
                onPressed: () => _tampilkanInfoKelulusan(context),
              ),
              const Spacer(),
              kelulusanAsync.when(
                data: (kel) {
                  if (!kel.adaData) {
                    return Text('Belum ada data', style: Gaya.catatan);
                  }
                  return Text(
                    FormatAngka.persenSatuDesimal(kel.angka),
                    style: Gaya.angka,
                  );
                },
                loading: () => Text('Memuat...', style: Gaya.catatan),
                error: (e, s) => Text('Gagal memuat', style: Gaya.catatan),
              ),
            ],
          ),
          const SizedBox(height: 8),

          kelulusanAsync.when(
            data: (kel) {
              if (!kel.adaData) {
                return const SizedBox.shrink();
              }
              final rasio = (kel.angka / 100.0).clamp(0.0, 1.0);
              return Container(
                height: 8,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Warna.tintaAngkat,
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: rasio,
                  child: Container(color: Warna.laut),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e, s) => Row(
              children: [
                Expanded(
                  child: Text('Tingkat kelulusan belum bisa dimuat.', style: Gaya.catatan),
                ),
                TextButton(
                  onPressed: () => ref.refresh(kelulusanProvider(kode)),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Bagian Lokasi
          Text('Lokasi', style: Gaya.judulLayar.copyWith(fontSize: 18)),
          const SizedBox(height: 12),

          if (k == null) ...[
            Text('Lokasi belum diisi oleh kampus.', style: Gaya.isi.copyWith(color: Warna.kapurRedup)),
          ] else ...[
            // Peta mini 120dp tidak interaktif dengan titik kunyit & cincin
            Container(
              height: 120,
              width: double.infinity,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: Warna.tintaAngkat,
                border: Border.all(color: Warna.garis, width: 1),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final centerPt = GridKetuk.proyeksikan(k.lintang, k.bujur);
                  final canvasX = centerPt.x * constraints.maxWidth;
                  final canvasY = centerPt.y * constraints.maxWidth;

                  const skala = 5.0;
                  final tx = (constraints.maxWidth / 2) - (canvasX * skala);
                  final ty = (constraints.maxHeight / 2) - (canvasY * skala);

                  final kontrol = TransformationController(
                    Matrix4.translationValues(tx, ty, 0.0)
                      ..scaleByDouble(skala, skala, 1.0, 1.0),
                  );

                  final titikBuffer = dataParsed?.titikBiasaBuffer ?? Float32List(0);
                  final titikSorot = Float32List(2)
                    ..[0] = centerPt.x
                    ..[1] = centerPt.y;

                  return CustomPaint(
                    painter: PetaTitikPainter(
                      pathIndonesia: pathIndonesiaAsync.value,
                      redup: titikBuffer,
                      sorot: titikSorot,
                      kontrol: kontrol,
                      sapuan: const AlwaysStoppedAnimation(1.0),
                      adaFilter: true,
                      cincinTunggal: Offset(centerPt.x, centerPt.y),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            if (k.dikoreksi) ...[
              Text(
                'Lintang dan bujur di sumber tertukar. Sudah dibetulkan.',
                style: Gaya.catatan.copyWith(color: Warna.kunyit),
              ),
              const SizedBox(height: 4),
            ],

            Text('Lintang ${FormatAngka.koordinat(k.lintang)}', style: Gaya.angka),
            const SizedBox(height: 2),
            Text('Bujur ${FormatAngka.koordinat(k.bujur)}', style: Gaya.angka),
          ],
          const SizedBox(height: 24),

          // Tombol Aksi: Buka Peta & Salin Kode
          Row(
            children: [
              if (k != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _bukaPeta(k.lintang, k.bujur, kampus.nama),
                    child: const Text('Buka di aplikasi peta'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: kampus.kode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Kode PT berhasil disalin'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text('Salin kode'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
