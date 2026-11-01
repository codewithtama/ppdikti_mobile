import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/format/status_akademik.dart';
import '../../core/theme/tokens.dart';
import '../../data/model/pencarian_global.dart';
import 'bagikan_profil_sheet.dart';
import 'pencarian_vm.dart';

class DetailDosenLayar extends ConsumerStatefulWidget {
  const DetailDosenLayar({
    super.key,
    required this.id,
    this.ringkasan,
  });

  final String id;
  final HasilDosen? ringkasan;

  @override
  ConsumerState<DetailDosenLayar> createState() => _DetailDosenLayarState();
}

class _DetailDosenLayarState extends ConsumerState<DetailDosenLayar> {
  late Future<DetailDosen?> _futureDetail;

  @override
  void initState() {
    super.initState();
    _futureDetail = ref.read(pencarianRepoProvider).ambilDetailDosen(
          widget.id,
          fallback: widget.ringkasan,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Warna.tinta,
      appBar: AppBar(
        title: const Text('Profil Dosen'),
        elevation: 0,
        backgroundColor: Warna.tinta,
        foregroundColor: Warna.kapur,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.shareNetwork),
            tooltip: 'Bagikan Profil / Unduh PDF',
            onPressed: () {
              final dsn = widget.ringkasan;
              _futureDetail.then((d) {
                if (!context.mounted) return;
                final target = d ?? (dsn != null ? DetailDosen(ringkasan: dsn) : null);
                if (target != null) {
                  BagikanProfilSheet.tampilkan(context, dosen: target);
                }
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<DetailDosen?>(
        future: _futureDetail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && widget.ringkasan == null) {
            return const Center(
              child: CircularProgressIndicator(color: Warna.kunyit, strokeWidth: 2),
            );
          }

          final detail = snapshot.data;
          final dsn = detail?.ringkasan ?? widget.ringkasan;

          if (dsn == null) {
            return const Center(
              child: Text(
                'Data dosen tidak ditemukan.',
                style: TextStyle(color: Warna.kapurRedup),
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Profil Dosen
                Container(
                  color: Warna.tintaAngkat,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Builder(
                        builder: (context) {
                          final statusRaw = dsn.status;
                          final warnaStatus = StatusAkademikHelper.warnaTeks(statusRaw);
                          final labelStatus = (statusRaw != null && statusRaw.isNotEmpty)
                              ? statusRaw.toUpperCase()
                              : 'TIDAK TERSEDIA';

                          return Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: warnaStatus.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(
                                    color: warnaStatus,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  labelStatus,
                                  style: TextStyle(
                                    color: warnaStatus,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              if (dsn.pendidikanTertinggi != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Warna.garis,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Text(
                                    dsn.pendidikanTertinggi!,
                                    style: const TextStyle(
                                      color: Warna.kapur,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        dsn.nama,
                        style: const TextStyle(
                          color: Warna.kapur,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'NIDN / NUP: ${dsn.nidn.isNotEmpty ? dsn.nidn : "-"}',
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

                // Tombol Aksi Bagikan / Unduh PDF
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Warna.kunyit,
                      side: const BorderSide(color: Warna.kunyit, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(PhosphorIconsRegular.shareNetwork, size: 18),
                    label: const Text(
                      'Bagikan Profil & Unduh Dokumen PDF',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    onPressed: () {
                      final target = detail ?? DetailDosen(ringkasan: dsn);
                      BagikanProfilSheet.tampilkan(context, dosen: target);
                    },
                  ),
                ),

                // Data Penugasan
                _GrupInformasiDosen(
                  judul: 'Instansi & Penugasan',
                  item: [
                    _BarisInfoDosen(label: 'Perguruan Tinggi', nilai: dsn.namaPt),
                    _BarisInfoDosen(label: 'Homebase Prodi', nilai: dsn.namaProdi),
                    if (dsn.jabatanAkademik != null)
                      _BarisInfoDosen(label: 'Jabatan Fungsional', nilai: dsn.jabatanAkademik!),
                    if (detail != null)
                      _BarisInfoDosen(label: 'Ikatan Kerja', nilai: detail.statusIkatanKerja),
                    if (detail?.jenisKelamin != null)
                      _BarisInfoDosen(label: 'Jenis Kelamin', nilai: detail!.jenisKelamin!),
                  ],
                ),

                // Riwayat Pendidikan
                if (detail != null && detail.riwayatPendidikan.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      'Riwayat Pendidikan'.toUpperCase(),
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
                        for (int i = 0; i < detail.riwayatPendidikan.length; i++) ...[
                          if (i > 0) const Divider(height: 1, color: Warna.garis),
                          Container(
                            color: Warna.tintaAngkat,
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Warna.garis,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Text(
                                    detail.riwayatPendidikan[i].jenjang,
                                    style: const TextStyle(
                                      color: Warna.kunyit,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        detail.riwayatPendidikan[i].bidangStudi,
                                        style: const TextStyle(
                                          color: Warna.kapur,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        detail.riwayatPendidikan[i].perguruanTinggi,
                                        style: const TextStyle(
                                          color: Warna.kapurRedup,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (detail.riwayatPendidikan[i].tahunLulus.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Lulus: ${detail.riwayatPendidikan[i].tahunLulus}',
                                          style: const TextStyle(
                                            color: Warna.kapurRedup,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // Riwayat Mengajar
                if (detail != null && detail.riwayatMengajar.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      'Riwayat Mengajar'.toUpperCase(),
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
                        for (int i = 0; i < detail.riwayatMengajar.length; i++) ...[
                          if (i > 0) const Divider(height: 1, color: Warna.garis),
                          Container(
                            color: Warna.tintaAngkat,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        detail.riwayatMengajar[i].mataKuliah,
                                        style: const TextStyle(
                                          color: Warna.kapur,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'Kelas ${detail.riwayatMengajar[i].kelas} · ${detail.riwayatMengajar[i].perguruanTinggi}',
                                        style: const TextStyle(
                                          color: Warna.kapurRedup,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Warna.garis,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Text(
                                    detail.riwayatMengajar[i].semester,
                                    style: const TextStyle(
                                      color: Warna.kapurRedup,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GrupInformasiDosen extends StatelessWidget {
  const _GrupInformasiDosen({required this.judul, required this.item});
  final String judul;
  final List<_BarisInfoDosen> item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            judul.toUpperCase(),
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
              for (int i = 0; i < item.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: Warna.garis),
                item[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BarisInfoDosen extends StatelessWidget {
  const _BarisInfoDosen({required this.label, required this.nilai});
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

