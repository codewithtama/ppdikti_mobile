import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/format/angka.dart';
import '../../core/format/tanggal.dart';
import '../../core/theme/tokens.dart';
import '../../data/model/detail_kampus.dart';
import '../../data/model/kelulusan.dart';
import '../../data/repo/kampus_repo.dart';
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
              Text(
                'Tentang tingkat kelulusan',
                style: Gaya.judulLayar.copyWith(fontSize: 18),
              ),
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

  Future<void> _bukaTautan(String urlString) async {
    String formatted = urlString.trim();
    if (!formatted.startsWith('http://') && !formatted.startsWith('https://')) {
      formatted = 'https://$formatted';
    }
    final uri = Uri.tryParse(formatted);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _telepon(String nomor) async {
    final clean = nomor.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _kirimEmail(String email) async {
    final uri = Uri.parse('mailto:${email.trim()}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _bukaGoogleMaps(
    double lintang,
    double bujur,
    String nama,
  ) async {
    final uri = Uri.parse('geo:$lintang,$bujur?q=$lintang,$bujur($nama)');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      final webUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lintang,$bujur',
      );
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  Color _warnaStatus(String status) {
    final st = status.toLowerCase();
    if (st.contains('aktif') && !st.contains('non')) {
      return const Color(0xFF22C55E);
    }
    if (st.contains('alih')) return const Color(0xFF3B82F6);
    if (st.contains('tutup')) return const Color(0xFFEF4444);
    if (st.contains('bina')) return const Color(0xFFF59E0B);
    return Warna.kunyit;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kampus = ref.watch(detailKampusProvider(kode));
    final profilAsync = ref.watch(detailProfilKampusProvider(kode));
    final kelulusanAsync = ref.watch(kelulusanProvider(kode));
    final dataParsed = ref.watch(daftarKampusProvider).value;
    final pathIndonesiaAsync = ref.watch(petaIndonesiaPathProvider);

    if (kampus == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Kampus tidak ditemukan.', style: Gaya.isi)),
      );
    }

    final k = kampus.koordinat;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Kampus'),
        actions: [
          if (k != null)
            IconButton(
              icon: const Icon(PhosphorIconsRegular.navigationArrow),
              tooltip: 'Buka di Google Maps',
              onPressed: () => _bukaGoogleMaps(k.lintang, k.bujur, kampus.nama),
            ),
        ],
      ),
      body: profilAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Warna.kunyit, strokeWidth: 2),
              SizedBox(height: 12),
              Text(
                'Memuat profil lengkap kampus...',
                style: TextStyle(color: Warna.kapurRedup),
              ),
            ],
          ),
        ),
        error: (err, _) => _buildTampilanDetail(
          context: context,
          ref: ref,
          detail: DetailKampus(
            idSp: kampus.idSp,
            kode: kampus.kode,
            nama: kampus.nama,
            kelompok: kampus.kelompok,
            pembina: kampus.pembina,
            kabKota: kampus.kota,
            lintang: k?.lintang,
            bujur: k?.bujur,
          ),
          kelulusanAsync: kelulusanAsync,
          dataParsed: dataParsed,
          pathIndonesia: pathIndonesiaAsync.value,
        ),
        data: (detail) => _buildTampilanDetail(
          context: context,
          ref: ref,
          detail:
              detail ??
              DetailKampus(
                idSp: kampus.idSp,
                kode: kampus.kode,
                nama: kampus.nama,
                kelompok: kampus.kelompok,
                pembina: kampus.pembina,
                kabKota: kampus.kota,
                lintang: k?.lintang,
                bujur: k?.bujur,
              ),
          kelulusanAsync: kelulusanAsync,
          dataParsed: dataParsed,
          pathIndonesia: pathIndonesiaAsync.value,
        ),
      ),
    );
  }

  Widget _buildTampilanDetail({
    required BuildContext context,
    required WidgetRef ref,
    required DetailKampus detail,
    required AsyncValue<Kelulusan> kelulusanAsync,
    required DataParsedKampus? dataParsed,
    required Path? pathIndonesia,
  }) {
    final statusColor = _warnaStatus(detail.status);
    final kLintang = detail.lintang;
    final kBujur = detail.bujur;
    final adaKoordinat = kLintang != null && kBujur != null;

    // Format alamat lengkap
    final bagianAlamat =
        [
              detail.alamat,
              detail.kabKota,
              detail.provinsi,
              if (detail.kodePos != null && detail.kodePos!.isNotEmpty)
                'Kode Pos ${detail.kodePos}',
            ]
            .where(
              (s) => s != null && s.trim().isNotEmpty && s != 'Tidak Diisi',
            )
            .join(', ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        // 1. Header: Logo 64dp, Nama Kampus, Singkatan, dan Badge Status
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Warna.tintaAngkat,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Warna.garis, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LogoKampus(idSp: detail.idSp, nama: detail.nama, ukuran: 64),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.nama,
                      style: const TextStyle(
                        color: Warna.kapur,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    if (detail.namaSingkat != null &&
                        detail.namaSingkat!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        detail.namaSingkat!,
                        style: const TextStyle(
                          color: Warna.kunyit,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: statusColor, width: 1),
                          ),
                          child: Text(
                            detail.status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Kode ${detail.kode}',
                          style: const TextStyle(
                            color: Warna.kapurRedup,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. Data Utama (Sesuai Kolom Kiri Gambar: Kode, Status, Akreditasi, Biaya Kuliah, Indikator, Tgl Berdiri)
        const Text(
          'PROFIL PERGURUAN TINGGI',
          style: TextStyle(
            color: Warna.kunyit,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Warna.tintaAngkat,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Warna.garis, width: 1),
          ),
          child: Column(
            children: [
              _BarisInfoDetail(
                label: 'Kode',
                nilai: detail.kode,
                isMonospace: true,
              ),
              const Divider(color: Warna.garis, height: 16),
              _BarisInfoDetail(
                label: 'Status',
                nilai: detail.status,
                warnaNilai: statusColor,
              ),
              const Divider(color: Warna.garis, height: 16),
              _BarisInfoDetail(
                label: 'Akreditasi',
                nilai: detail.akreditasi.isNotEmpty
                    ? detail.akreditasi
                    : 'Belum Terakreditasi',
                warnaNilai:
                    detail.akreditasi.toLowerCase().contains('unggul') ||
                        detail.akreditasi.toLowerCase().contains('baik')
                    ? Warna.kunyit
                    : Warna.kapur,
              ),
              const Divider(color: Warna.garis, height: 16),
              _BarisInfoDetail(
                label: 'Biaya Kuliah',
                nilai: detail.biayaKuliah.isNotEmpty
                    ? 'Rp${detail.biayaKuliah}'
                    : 'Rp -',
                warnaNilai: Warna.laut,
              ),
              const Divider(color: Warna.garis, height: 16),
              const _BarisInfoDetail(
                label: 'Indikator Kelengkapan Data',
                nilai: '—',
              ),
              const Divider(color: Warna.garis, height: 16),
              _BarisInfoDetail(
                label: 'Tanggal Berdiri',
                nilai:
                    detail.tglBerdiri != null && detail.tglBerdiri!.isNotEmpty
                    ? FormatTanggal.tanggal(detail.tglBerdiri!)
                    : '—',
              ),
              if (detail.kelompok.isNotEmpty) ...[
                const Divider(color: Warna.garis, height: 16),
                _BarisInfoDetail(label: 'Kelompok', nilai: detail.kelompok),
              ],
              if (detail.pembina.isNotEmpty) ...[
                const Divider(color: Warna.garis, height: 16),
                _BarisInfoDetail(label: 'Pembina', nilai: detail.pembina),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 3. Legalitas & Kontak (Sesuai Kolom Kanan Gambar)
        const Text(
          'LEGALITAS & KONTAK RESMI',
          style: TextStyle(
            color: Warna.kunyit,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Warna.tintaAngkat,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Warna.garis, width: 1),
          ),
          child: Column(
            children: [
              _BarisInfoDetail(
                label: 'No SK Pendirian',
                nilai:
                    detail.noSkPendirian != null &&
                        detail.noSkPendirian!.isNotEmpty
                    ? detail.noSkPendirian!
                    : '—',
              ),
              const Divider(color: Warna.garis, height: 16),
              _BarisInfoDetail(
                label: 'Tanggal SK Pendirian',
                nilai:
                    detail.tglSkPendirian != null &&
                        detail.tglSkPendirian!.isNotEmpty
                    ? FormatTanggal.tanggal(detail.tglSkPendirian!)
                    : '—',
              ),
              const Divider(color: Warna.garis, height: 16),
              _BarisKontakAksi(
                icon: PhosphorIconsRegular.phone,
                label: 'Telepon',
                nilai: detail.telepon != null && detail.telepon!.isNotEmpty
                    ? detail.telepon!
                    : '—',
                onTap: detail.telepon != null && detail.telepon!.isNotEmpty
                    ? () => _telepon(detail.telepon!)
                    : null,
              ),
              if (detail.fax != null && detail.fax!.isNotEmpty) ...[
                const Divider(color: Warna.garis, height: 16),
                _BarisInfoDetail(label: 'Fax', nilai: detail.fax!),
              ],
              const Divider(color: Warna.garis, height: 16),
              _BarisKontakAksi(
                icon: PhosphorIconsRegular.envelopeSimple,
                label: 'Email',
                nilai: detail.email != null && detail.email!.isNotEmpty
                    ? detail.email!
                    : '—',
                onTap: detail.email != null && detail.email!.isNotEmpty
                    ? () => _kirimEmail(detail.email!)
                    : null,
              ),
              const Divider(color: Warna.garis, height: 16),
              _BarisKontakAksi(
                icon: PhosphorIconsRegular.globe,
                label: 'Website',
                nilai: detail.website != null && detail.website!.isNotEmpty
                    ? detail.website!
                    : '—',
                onTap: detail.website != null && detail.website!.isNotEmpty
                    ? () => _bukaTautan(detail.website!)
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 4. Alamat & Lokasi
        const Text(
          'ALAMAT KAMPUS',
          style: TextStyle(
            color: Warna.kunyit,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Warna.tintaAngkat,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Warna.garis, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    PhosphorIconsFill.mapPin,
                    color: Color(0xFFEA4335),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bagianAlamat.isNotEmpty
                          ? bagianAlamat
                          : 'Alamat belum diisi oleh kampus.',
                      style: const TextStyle(
                        color: Warna.kapur,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              if (adaKoordinat) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(
                      PhosphorIconsRegular.navigationArrow,
                      size: 16,
                    ),
                    onPressed: () =>
                        _bukaGoogleMaps(kLintang, kBujur, detail.nama),
                    label: const Text('Buka Navigasi di Google Maps'),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 5. Bagian Tingkat Kelulusan
        Row(
          children: [
            Text(
              'Tingkat kelulusan',
              style: Gaya.judulLayar.copyWith(fontSize: 18),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(
                Icons.info_outline,
                size: 18,
                color: Warna.kapurRedup,
              ),
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
            if (!kel.adaData) return const SizedBox.shrink();
            final rasio = (kel.angka / 100.0).clamp(0.0, 1.0);
            return Container(
              height: 8,
              width: double.infinity,
              decoration: const BoxDecoration(color: Warna.tintaAngkat),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: rasio,
                child: Container(color: Warna.laut),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (e, s) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 28),

        // 6. Peta Sebaran Kampus
        if (adaKoordinat) ...[
          Text('Peta Indonesia', style: Gaya.judulLayar.copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => context.push('/peta?kode=${detail.kode}'),
            child: Stack(
              children: [
                Container(
                  height: 130,
                  width: double.infinity,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: Warna.tintaAngkat,
                    border: Border.all(color: Warna.garis, width: 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final centerPt = GridKetuk.proyeksikan(kLintang, kBujur);
                      final canvasX = centerPt.x * constraints.maxWidth;
                      final canvasY = centerPt.y * constraints.maxWidth;

                      const skala = 5.0;
                      final tx = (constraints.maxWidth / 2) - (canvasX * skala);
                      final ty =
                          (constraints.maxHeight / 2) - (canvasY * skala);

                      final kontrol = TransformationController(
                        Matrix4.translationValues(tx, ty, 0.0)
                          ..scaleByDouble(skala, skala, 1.0, 1.0),
                      );

                      final titikBuffer =
                          dataParsed?.titikBiasaBuffer ?? Float32List(0);
                      final titikSorot = Float32List(2)
                        ..[0] = centerPt.x
                        ..[1] = centerPt.y;

                      return CustomPaint(
                        painter: PetaTitikPainter(
                          pathIndonesia: pathIndonesia,
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
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Warna.tinta.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Warna.kunyit, width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIconsRegular.cornersOut,
                          color: Warna.kunyit,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Buka Peta Interaktif',
                          style: TextStyle(
                            color: Warna.kunyit,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // 7. Tombol Aksi Bawah
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(PhosphorIconsRegular.copy, size: 16),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: detail.kode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kode PT berhasil disalin'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                label: const Text('Salin Kode PT'),
              ),
            ),
            if (adaKoordinat) ...[
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(PhosphorIconsRegular.mapPin, size: 16),
                  onPressed: () => context.push('/peta?kode=${detail.kode}'),
                  label: const Text('Buka di Peta'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _BarisInfoDetail extends StatelessWidget {
  const _BarisInfoDetail({
    required this.label,
    required this.nilai,
    this.warnaNilai,
    this.isMonospace = false,
  });

  final String label;
  final String nilai;
  final Color? warnaNilai;
  final bool isMonospace;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(color: Warna.kapurRedup, fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            nilai,
            style: TextStyle(
              color: warnaNilai ?? Warna.kapur,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: isMonospace ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _BarisKontakAksi extends StatelessWidget {
  const _BarisKontakAksi({
    required this.icon,
    required this.label,
    required this.nilai,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String nilai;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool bisaDitekan = onTap != null && nilai != '—';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: bisaDitekan ? Warna.kunyit : Warna.kapurRedup,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Warna.kapurRedup,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                nilai,
                style: TextStyle(
                  color: bisaDitekan ? Warna.kunyit : Warna.kapur,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: bisaDitekan ? TextDecoration.underline : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
