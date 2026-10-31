import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/izin/layanan_izin_android.dart';
import '../../core/ketentuan/layanan_ketentuan.dart';
import '../../core/theme/tokens.dart';

class KetentuanLayar extends StatefulWidget {
  const KetentuanLayar({super.key});

  @override
  State<KetentuanLayar> createState() => _KetentuanLayarState();
}

class _KetentuanLayarState extends State<KetentuanLayar> {
  static const int _durasiAwal = 10;
  int _sisaDetik = _durasiAwal;
  Timer? _timer;
  bool _sedangMemproses = false;

  @override
  void initState() {
    super.initState();
    _mulaiTimer();
  }

  void _mulaiTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_sisaDetik > 1) {
          _sisaDetik--;
        } else {
          _sisaDetik = 0;
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _tanganiSetuju() async {
    if (_sisaDetik > 0 || _sedangMemproses) return;

    setState(() => _sedangMemproses = true);

    try {
      // 1. Simpan status persetujuan secara permanen di storage
      await LayananKetentuan.simpanPersetujuan();

      // 2. Periksa izin instalasi paket tidak dikenal di Android untuk update OTA
      if (Platform.isAndroid && mounted) {
        final sudahBisa = await LayananIzinAndroid.bisaInstallPaket();
        if (!sudahBisa && mounted) {
          await _tampilkanDialogIzinOta();
        }
      }

      if (mounted) {
        context.go('/beranda');
      }
    } finally {
      if (mounted) {
        setState(() => _sedangMemproses = false);
      }
    }
  }

  Future<void> _tampilkanDialogIzinOta() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Warna.tintaAngkat,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Warna.garis, width: 1),
          ),
          title: Row(
            children: [
              const Icon(
                PhosphorIconsRegular.shieldCheck,
                color: Warna.kunyit,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Izin Pembaruan (OTA)',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        color: Warna.kapur,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          content: Text(
            'Untuk memastikan Anda selalu mendapatkan pembaruan mandiri (Over-The-Air) berkas APK resmi secara aman dan langsung, silakan aktifkan izin "Izinkan dari sumber ini" pada halaman pengaturan sistem.',
            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  color: Warna.kapurRedup,
                  height: 1.5,
                ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Lain Kali',
                style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                      color: Warna.kapurRedup,
                    ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Warna.kunyit,
                foregroundColor: Warna.tinta,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                await LayananIzinAndroid.bukaPengaturanInstallPaket();
              },
              child: const Text(
                'Buka Pengaturan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _tanganiTolak() {
    // Keluar dari aplikasi secara bersih
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final tombolAktif = _sisaDetik == 0 && !_sedangMemproses;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Warna.tinta,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Warna.tinta,
          title: Row(
            children: [
              const Icon(
                PhosphorIconsRegular.scroll,
                color: Warna.kunyit,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Ketentuan & Kebijakan',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Warna.kapur,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: Warna.garis, height: 1),
          ),
        ),
        body: Column(
          children: [
            // Konten ketentuan yang dapat digulir
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Warna.tintaAngkat,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Warna.garis, width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              PhosphorIconsRegular.info,
                              color: Warna.kunyit,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Harap membaca ketentuan berikut sebelum menggunakan PDDikti Mobile. Dokumen ini hanya muncul 1 kali.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Warna.kapurRedup,
                                      height: 1.4,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      _bangunBagian(
                        nomor: '1',
                        judul: 'Sumber Data & Sifat Klien',
                        isi: 'PDDikti Mobile adalah klien antarmuka publik luring (offline-first) mandiri yang mengambil data dari REST Gateway publik Pangkalan Data Pendidikan Tinggi (PDDikti) Kementerian Pendidikan Tinggi, Sains, dan Teknologi Republik Indonesia. Aplikasi ini tidak berafiliasi secara komersial dengan pihak mana pun.',
                      ),

                      _bangunBagian(
                        nomor: '2',
                        judul: 'Pembaruan Mandiri (Over-The-Air / OTA)',
                        isi: 'Untuk memastikan integritas dan performa keamanan standar 2026, aplikasi ini memiliki mekanisme pembaruan berkas APK resmi langsung dari rilis terverifikasi dengan checksum SHA-256 tanpa perantara tidak resmi. Izin instalasi paket diperlukan untuk memungkinkan proses pembaruan ini berjalan di perangkat Anda.',
                      ),

                      _bangunBagian(
                        nomor: '3',
                        judul: 'Privasi & Keamanan Pengguna',
                        isi: 'Aplikasi ini tidak mengumpulkan data pribadi, tidak meminta akun login pengguna, dan tidak menyematkan pelacak analitik pihak ketiga. Seluruh riwayat pencarian disimpan secara lokal pada penyimpanan perangkat Anda.',
                      ),

                      _bangunBagian(
                        nomor: '4',
                        judul: 'Akurasi & Validitas Data Akademik',
                        isi: 'Seluruh data mahasiswa, dosen, program studi, dan perguruan tinggi yang ditampilkan merupakan hasil pelaporan berkala dari masing-masing perguruan tinggi ke pangkalan data nasional. Jika terdapat ketidaksesuaian data akademik, perbaikan dilakukan melalui perguruan tinggi terkait.',
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Bar indikator timer & aksi bawah
            Container(
              decoration: const BoxDecoration(
                color: Warna.tinta,
                border: Border(
                  top: BorderSide(color: Warna.garis, width: 1),
                ),
              ),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 14,
                bottom: MediaQuery.of(context).padding.bottom + 14,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Info sisa detik
                  if (_sisaDetik > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          PhosphorIconsRegular.clockCountdown,
                          color: Warna.kunyit,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Membaca ketentuan: $_sisaDetik detik tersisa',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Warna.kunyit,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: (_durasiAwal - _sisaDetik) / _durasiAwal,
                        backgroundColor: Warna.tintaAngkat,
                        valueColor: const AlwaysStoppedAnimation<Color>(Warna.kunyit),
                        minHeight: 3,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Tombol Aksi (Tolak & Setuju)
                  Row(
                    children: [
                      // Tombol Tolak
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Warna.garis, width: 1),
                            foregroundColor: Warna.kapurRedup,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _tanganiTolak,
                          child: const Text(
                            'Tolak & Keluar',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Tombol Setuju
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: tombolAktif ? Warna.kunyit : Warna.tintaAngkat,
                            foregroundColor: tombolAktif ? Warna.tinta : Warna.garisTegas,
                            disabledBackgroundColor: Warna.tintaAngkat,
                            disabledForegroundColor: Warna.garisTegas,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: tombolAktif ? Warna.kunyit : Warna.garis,
                                width: 1,
                              ),
                            ),
                          ),
                          onPressed: tombolAktif ? _tanganiSetuju : null,
                          child: _sedangMemproses
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Warna.tinta,
                                  ),
                                )
                              : Text(
                                  _sisaDetik > 0 ? 'Setuju (${_sisaDetik}s)' : 'Setuju & Lanjut',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
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
    );
  }

  Widget _bangunBagian({
    required String nomor,
    required String judul,
    required String isi,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Warna.kunyit.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  nomor,
                  style: const TextStyle(
                    color: Warna.kunyit,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  judul,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Warna.kapur,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              isi,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Warna.kapurRedup,
                    height: 1.55,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

