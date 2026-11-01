import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/format/angka.dart';
import '../../core/format/tanggal.dart';
import '../../core/net/galat.dart';
import '../../core/ota/layanan_pembaruan.dart';
import '../../core/ota/model_pembaruan.dart';
import '../../core/ota/sheet_pembaruan.dart';
import '../../core/theme/tokens.dart';
import '../kampus/kampus_vm.dart';
import '../pencarian/pencarian_vm.dart';
import 'beranda_vm.dart';
import 'bidang_ilmu_tabel.dart';
import 'ledger.dart';
import 'peta/peta_tertanam.dart';

class BerandaLayar extends ConsumerStatefulWidget {
  const BerandaLayar({super.key});

  @override
  ConsumerState<BerandaLayar> createState() => _BerandaLayarState();
}

class _BerandaLayarState extends ConsumerState<BerandaLayar> {
  bool _sudahPeriksaOta = false;
  InfoPembaruan? _infoPembaruanTersedia;
  String? _versiLokal;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _periksaOtaOtomatis();
    });
  }

  Future<void> _periksaOtaOtomatis() async {
    if (_sudahPeriksaOta || !mounted) return;
    _sudahPeriksaOta = true;

    try {
      final layanan = ref.read(layananPembaruanProvider);
      final status = await layanan.periksaPembaruan();
      if (status.adaPembaruan && status.info != null && mounted) {
        setState(() {
          _infoPembaruanTersedia = status.info;
          _versiLokal = status.versiSaatIni;
        });

        await SheetPembaruan.tampilkan(
          context: context,
          info: status.info!,
          versiSaatIni: status.versiSaatIni,
          layanan: layanan,
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final statusUnduhAsync = ref.watch(daftarKampusProvider);
    final progressPesan = ref.watch(progressDaftarKampusProvider);
    final berandaAsync = ref.watch(berandaProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDDikti Mobile'),
        actions: [
          if (_infoPembaruanTersedia != null)
            IconButton(
              icon: const Badge(
                backgroundColor: Warna.kunyit,
                child: Icon(PhosphorIconsRegular.arrowCircleDown, color: Warna.kunyit, size: 24),
              ),
              tooltip: 'Pembaruan v${_infoPembaruanTersedia!.versi} tersedia',
              onPressed: () {
                SheetPembaruan.tampilkan(
                  context: context,
                  info: _infoPembaruanTersedia!,
                  versiSaatIni: _versiLokal ?? '1.0.0',
                  layanan: ref.read(layananPembaruanProvider),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.info_outline, size: 22),
            tooltip: 'Tentang aplikasi',
            onPressed: () => context.push('/tentang'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: statusUnduhAsync.when(
        loading: () {
          final pesan = progressPesan ?? 'Mengunduh daftar kampus (sekitar 1,2 MB)';
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                pesan,
                style: Gaya.isi.copyWith(color: Warna.kapurRedup),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
        error: (err, stack) {
          final pesan = err is Galat
              ? err.pesan
              : 'Daftar kampus belum pernah diunduh dan tidak ada sambungan internet.';
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pesan,
                    style: Gaya.isi,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.read(daftarKampusProvider.notifier).segarkan(),
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            ),
          );
        },
        data: (dataKampus) {
          final titikBisaDigambar = dataKampus.semuaTitik.length;
          final totalKampus = dataKampus.daftarKampus.length;

          return RefreshIndicator(
            color: Warna.kunyit,
            backgroundColor: Warna.tintaAngkat,
            onRefresh: () async {
              await Future.wait([
                ref.refresh(berandaProvider.future),
                ref.read(daftarKampusProvider.notifier).segarkan(),
              ]);
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                // Indikator Offline tipis jika data dari cache (Section 5.2)
                if (dataKampus.dariCache)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    color: Warna.tintaAngkat,
                    child: Text(
                      'Offline. Data diunduh ${FormatTanggal.tanggal(dataKampus.waktuUnduh)}.',
                      style: Gaya.catatan,
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tombol pencarian semu yang membuka tab Pencarian dengan autofokus
                      InkWell(
                        onTap: () {
                          ref.read(pencarianGlobalProvider.notifier).aturKategori(KategoriPencarian.semua);
                          context.go('/kampus?fokus=1');
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Warna.tintaAngkat,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Warna.garisTegas, width: 1),
                          ),
                          child: const Row(
                            children: [
                              Icon(PhosphorIconsRegular.magnifyingGlass, size: 18, color: Warna.kunyit),
                              SizedBox(width: 10),
                              Text(
                                'Cari mahasiswa, dosen, kampus, prodi...',
                                style: TextStyle(color: Warna.kapurRedup, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Peta Titik Tertanam
                      const PetaTertanamWidget(),
                      const SizedBox(height: 8),

                      // Catatan koordinat di bawah peta (Section 5.2)
                      Text(
                        '${FormatAngka.ribuan(titikBisaDigambar)} dari ${FormatAngka.ribuan(totalKampus)} kampus di daftar punya koordinat yang bisa digambar.',
                        style: Gaya.catatan,
                      ),
                      const SizedBox(height: 24),

                      // Ledger Statistik Beranda
                      berandaAsync.when(
                        loading: () => Text(
                          'Memuat data statistik...',
                          style: Gaya.catatan,
                        ),
                        error: (e, _) => Text(
                          'Statistik nasional belum bisa dimuat.',
                          style: Gaya.catatan,
                        ),
                        data: (beranda) {
                          final stat = beranda.data.statistik;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              LedgerWidget(
                                items: [
                                  ItemLedger(
                                    label: 'Kampus',
                                    nilai: FormatAngka.ribuan(stat.jumlahKampus),
                                    onTap: () {
                                      ref.read(pencarianGlobalProvider.notifier).aturKategori(KategoriPencarian.kampus);
                                      context.go('/kampus');
                                    },
                                  ),
                                  ItemLedger(
                                    label: 'Program studi',
                                    nilai: FormatAngka.ribuan(stat.jumlahProdi),
                                    onTap: () {
                                      ref.read(pencarianGlobalProvider.notifier).aturKategori(KategoriPencarian.prodi);
                                      context.go('/kampus?fokus=1');
                                    },
                                  ),
                                  ItemLedger(
                                    label: 'Dosen',
                                    nilai: FormatAngka.ribuan(stat.jumlahDosen),
                                    onTap: () {
                                      ref.read(pencarianGlobalProvider.notifier).aturKategori(KategoriPencarian.dosen);
                                      context.go('/kampus?fokus=1');
                                    },
                                  ),
                                  ItemLedger(
                                    label: 'Mahasiswa',
                                    nilai: FormatAngka.ribuan(stat.jumlahMahasiswa),
                                    onTap: () {
                                      ref.read(pencarianGlobalProvider.notifier).aturKategori(KategoriPencarian.mahasiswa);
                                      context.go('/kampus?fokus=1');
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),

                              // Tabel Bidang Ilmu
                              BidangIlmuTabel(
                                daftar: beranda.data.bidangIlmu,
                                angkaMahasiswaBeranda: stat.jumlahMahasiswa,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

