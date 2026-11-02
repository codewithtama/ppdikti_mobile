import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/tokens.dart';
import '../../data/model/pencarian_global.dart';
import '../komparasi/komparasi_vm.dart';

class DetailProdiLayar extends ConsumerWidget {
  const DetailProdiLayar({
    super.key,
    required this.id,
    required this.prodi,
  });

  final String id;
  final HasilProdi prodi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateKomparasi = ref.watch(komparasiProvider);
    final sudahDipilih = stateKomparasi.apakahProdiAda(prodi.id);

    return Scaffold(
      backgroundColor: Warna.tinta,
      appBar: AppBar(
        title: const Text('Program Studi'),
        elevation: 0,
        backgroundColor: Warna.tinta,
        foregroundColor: Warna.kapur,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              sudahDipilih ? PhosphorIconsFill.checkCircle : PhosphorIconsRegular.scales,
              color: sudahDipilih ? Warna.kunyit : Warna.kapur,
            ),
            tooltip: sudahDipilih ? 'Hapus dari komparasi' : 'Bandingkan Prodi',
            onPressed: () {
              final berhasil = ref.read(komparasiProvider.notifier).tambahProdi(prodi);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(berhasil
                      ? '${prodi.nama} ditambahkan ke komparasi'
                      : '${prodi.nama} dihapus dari komparasi'),
                  duration: const Duration(seconds: 2),
                  action: SnackBarAction(
                    label: 'Lihat',
                    textColor: Warna.kunyit,
                    onPressed: () => context.push('/komparasi'),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Prodi
            Container(
              color: Warna.tintaAngkat,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Warna.kunyit.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: Warna.kunyit, width: 1),
                        ),
                        child: Text(
                          prodi.jenjang,
                          style: const TextStyle(
                            color: Warna.kunyit,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Warna.laut.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: Warna.laut, width: 1),
                        ),
                        child: Text(
                          'AKREDITASI: ${prodi.akreditasi.toUpperCase()}',
                          style: const TextStyle(
                            color: Warna.laut,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    prodi.nama,
                    style: const TextStyle(
                      color: Warna.kapur,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    prodi.pt,
                    style: const TextStyle(
                      color: Warna.kapurRedup,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Warna.garis),

            // Informasi Rinci
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'Informasi Akademik'.toUpperCase(),
                style: const TextStyle(
                  color: Warna.kapurRedup,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Warna.garis, width: 1),
                  bottom: BorderSide(color: Warna.garis, width: 1),
                ),
              ),
              child: Column(
                children: [
                  _BarisInfoProdi(label: 'Program Studi', nilai: prodi.nama),
                  const Divider(height: 1, color: Warna.garis),
                  _BarisInfoProdi(label: 'Jenjang', nilai: prodi.jenjang),
                  const Divider(height: 1, color: Warna.garis),
                  _BarisInfoProdi(label: 'Perguruan Tinggi', nilai: prodi.pt),
                  const Divider(height: 1, color: Warna.garis),
                  _BarisInfoProdi(label: 'Akreditasi', nilai: prodi.akreditasi),
                  const Divider(height: 1, color: Warna.garis),
                  _BarisInfoProdi(label: 'Status Program', nilai: prodi.status),
                  if (prodi.rasioDosenMahasiswa != null) ...[
                    const Divider(height: 1, color: Warna.garis),
                    _BarisInfoProdi(label: 'Rasio Dosen / Mhs', nilai: prodi.rasioDosenMahasiswa!),
                  ],
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: OutlinedButton.icon(
                icon: Icon(
                  sudahDipilih ? PhosphorIconsFill.checkCircle : PhosphorIconsRegular.scales,
                  size: 18,
                  color: Warna.kunyit,
                ),
                label: Text(
                  sudahDipilih
                      ? 'Sedang Dibandingkan (Buka Komparasi)'
                      : 'Bandingkan Program Studi Ini',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Warna.kunyit,
                  side: const BorderSide(color: Warna.kunyit, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  if (sudahDipilih) {
                    context.push('/komparasi');
                  } else {
                    ref.read(komparasiProvider.notifier).tambahProdi(prodi);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${prodi.nama} ditambahkan ke komparasi'),
                        duration: const Duration(seconds: 2),
                        action: SnackBarAction(
                          label: 'Lihat',
                          textColor: Warna.kunyit,
                          onPressed: () => context.push('/komparasi'),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _BarisInfoProdi extends StatelessWidget {
  const _BarisInfoProdi({required this.label, required this.nilai});
  final String label;
  final String nilai;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Warna.tintaAngkat,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: Warna.kapurRedup,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              nilai,
              style: const TextStyle(
                color: Warna.kapur,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

