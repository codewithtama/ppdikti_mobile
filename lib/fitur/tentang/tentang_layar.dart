import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/format/tanggal.dart';
import '../../core/ota/layanan_pembaruan.dart';
import '../../core/ota/sheet_pembaruan.dart';
import '../../core/theme/tokens.dart';
import '../beranda/beranda_vm.dart';
import '../kampus/kampus_vm.dart';

class TentangLayar extends ConsumerWidget {
  const TentangLayar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kampusAsync = ref.watch(daftarKampusProvider);
    final berandaAsync = ref.watch(berandaProvider);

    final waktuKampus = kampusAsync.value?.waktuUnduh;
    final waktuBeranda = berandaAsync.value?.waktuCache;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          // Pernyataan Tidak Resmi (Section 9)
          Text(
            'Aplikasi ini tidak resmi dan tidak berafiliasi dengan Kemdiktisaintek. Data berasal dari pddikti.kemdiktisaintek.go.id.',
            style: Gaya.isi,
          ),
          const SizedBox(height: 24),

          const Divider(height: 1),
          const SizedBox(height: 20),

          // Tanggal Unduhan Terakhir
          Text('Waktu unduh data', style: Gaya.judulLayar.copyWith(fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            'Daftar kampus: ${waktuKampus != null ? FormatTanggal.tanggal(waktuKampus) : 'Belum dimuat'}',
            style: Gaya.label,
          ),
          const SizedBox(height: 4),
          Text(
            'Statistik beranda: ${waktuBeranda != null ? FormatTanggal.tanggal(waktuBeranda) : 'Belum dimuat'}',
            style: Gaya.label,
          ),
          const SizedBox(height: 16),

          // Tombol Perbarui Data (Section 9)
          OutlinedButton(
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Memperbarui daftar kampus...')),
              );
              await Future.wait([
                ref.read(daftarKampusProvider.notifier).segarkan(),
                ref.refresh(berandaProvider.future),
              ]);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data berhasil diperbarui.')),
                );
              }
            },
            child: const Text('Perbarui data'),
          ),
          const SizedBox(height: 28),

          const Divider(height: 1),
          const SizedBox(height: 20),

          // Versi Aplikasi & Pembaruan OTA
          Text('Versi aplikasi', style: Gaya.judulLayar.copyWith(fontSize: 16)),
          const SizedBox(height: 6),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final info = snapshot.data;
              final text = info != null
                  ? 'PDDikti Mobile v${info.version}+${info.buildNumber}'
                  : 'PDDikti Mobile 1.0.0';
              return Text(text, style: Gaya.label);
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(PhosphorIconsRegular.arrowClockwise, size: 18),
            label: const Text('Periksa pembaruan aplikasi (OTA)'),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Memeriksa versi rilis terbaru...')),
              );
              final layanan = ref.read(layananPembaruanProvider);
              final status = await layanan.periksaPembaruan();
              if (!context.mounted) return;
              if (status.adaPembaruan && status.info != null) {
                SheetPembaruan.tampilkan(
                  context: context,
                  info: status.info!,
                  versiSaatIni: status.versiSaatIni,
                  layanan: layanan,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(status.pesan ?? 'Aplikasi sudah menggunakan versi terbaru (v${status.versiSaatIni}).'),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 28),

          const Divider(height: 1),
          const SizedBox(height: 20),

          // Daftar Istilah
          Text('Daftar istilah', style: Gaya.judulLayar.copyWith(fontSize: 16)),
          const SizedBox(height: 12),
          _itemGlosarium('PTN', 'Perguruan Tinggi Negeri'),
          _itemGlosarium('PTS', 'Perguruan Tinggi Swasta'),
          _itemGlosarium('PTA', 'Perguruan Tinggi Keagamaan'),
          _itemGlosarium('PTK', 'Perguruan Tinggi Kedinasan di bawah kementerian atau lembaga'),
          _itemGlosarium('PTLN', 'Perguruan Tinggi Luar Negeri cabang Indonesia'),
          _itemGlosarium('LLDIKTI', 'Lembaga Layanan Pendidikan Tinggi, pembina PTS per wilayah'),
          _itemGlosarium('Kode PT', 'Kode nomor registrasi resmi perguruan tinggi di PDDikti'),
          const SizedBox(height: 20),

          const Divider(height: 1),
          const SizedBox(height: 20),

          // Catatan Ketergantungan API
          Text('Ketergantungan endpoint', style: Gaya.judulLayar.copyWith(fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            'Aplikasi ini bergantung pada endpoint yang tidak didokumentasikan secara resmi oleh Kemdiktisaintek. Apabila pihak kementerian mengubah struktur atau menutup akses publik, sebagian atau seluruh fungsi aplikasi dapat berhenti bekerja tanpa pemberitahuan.',
            style: Gaya.catatan,
          ),
          const SizedBox(height: 24),

          const Divider(height: 1),
          const SizedBox(height: 20),

          // Lisensi Font
          Text('Lisensi font', style: Gaya.judulLayar.copyWith(fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            'Archivo dan Source Serif 4 dilisensikan di bawah SIL Open Font License (OFL).',
            style: Gaya.catatan,
          ),
        ],
      ),
    );
  }

  Widget _itemGlosarium(String istilah, String arti) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(istilah, style: Gaya.isi.copyWith(color: Warna.kunyit, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(arti, style: Gaya.isi),
          ),
        ],
      ),
    );
  }
}

