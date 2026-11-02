import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/format/status_akademik.dart';
import '../../core/format/tanggal.dart';
import '../../core/theme/tokens.dart';
import '../../data/model/pencarian_global.dart';
import '../kartu_digital/kartu_digital_sheet.dart';
import 'bagikan_profil_sheet.dart';
import 'pencarian_vm.dart';

class DetailMahasiswaLayar extends ConsumerStatefulWidget {
  const DetailMahasiswaLayar({
    super.key,
    required this.id,
    this.ringkasan,
  });

  final String id;
  final HasilMahasiswa? ringkasan;

  @override
  ConsumerState<DetailMahasiswaLayar> createState() => _DetailMahasiswaLayarState();
}

class _DetailMahasiswaLayarState extends ConsumerState<DetailMahasiswaLayar> {
  late Future<DetailMahasiswa?> _futureDetail;

  @override
  void initState() {
    super.initState();
    _futureDetail = ref.read(pencarianRepoProvider).ambilDetailMahasiswa(
          widget.id,
          fallback: widget.ringkasan,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Warna.tinta,
      appBar: AppBar(
        title: const Text('Profil Mahasiswa'),
        elevation: 0,
        backgroundColor: Warna.tinta,
        foregroundColor: Warna.kapur,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.identificationCard),
            tooltip: 'Kartu Identitas Digital Mahasiswa',
            onPressed: () {
              final mhs = widget.ringkasan;
              _futureDetail.then((d) {
                if (!context.mounted) return;
                final target = d ?? (mhs != null ? DetailMahasiswa(ringkasan: mhs) : null);
                if (target != null) {
                  KartuDigitalSheet.tampilkan(context, mahasiswa: target);
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(PhosphorIconsRegular.shareNetwork),
            tooltip: 'Bagikan Profil / Unduh PDF',
            onPressed: () {
              final mhs = widget.ringkasan;
              _futureDetail.then((d) {
                if (!context.mounted) return;
                final target = d ?? (mhs != null ? DetailMahasiswa(ringkasan: mhs) : null);
                if (target != null) {
                  BagikanProfilSheet.tampilkan(context, mahasiswa: target);
                }
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<DetailMahasiswa?>(
        future: _futureDetail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && widget.ringkasan == null) {
            return const Center(
              child: CircularProgressIndicator(color: Warna.kunyit, strokeWidth: 2),
            );
          }

          final detail = snapshot.data;
          final mhs = detail?.ringkasan ?? widget.ringkasan;

          if (mhs == null) {
            return const Center(
              child: Text(
                'Data mahasiswa tidak ditemukan.',
                style: TextStyle(color: Warna.kapurRedup),
              ),
            );
          }

          final statusRaw = detail?.statusTerakhir ?? mhs.status;
          final warnaStatus = StatusAkademikHelper.warnaTeks(statusRaw);
          final labelStatus = (statusRaw != null && statusRaw.isNotEmpty)
              ? statusRaw.toUpperCase()
              : 'TIDAK TERSEDIA';

          final String formatTglMasuk = detail?.tanggalMasuk != null && detail!.tanggalMasuk!.isNotEmpty
              ? FormatTanggal.tanggal(detail.tanggalMasuk!)
              : (mhs.tahunMasuk ?? '-');

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Ringkasan Status & Nama
                Container(
                  color: Warna.tintaAngkat,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Row(
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
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Warna.garis,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          mhs.jenjang,
                          style: const TextStyle(
                            color: Warna.kapur,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: Warna.garis),

                // Tombol Aksi: Kartu Digital & Bagikan PDF
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Warna.kunyit,
                            foregroundColor: Warna.tinta,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(PhosphorIconsFill.identificationCard, size: 18),
                          label: const Text(
                            'Kartu Digital',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          onPressed: () {
                            final target = detail ?? DetailMahasiswa(ringkasan: mhs);
                            KartuDigitalSheet.tampilkan(context, mahasiswa: target);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Warna.kunyit,
                            side: const BorderSide(color: Warna.kunyit, width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(PhosphorIconsRegular.shareNetwork, size: 18),
                          label: const Text(
                            'Bagikan PDF',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          onPressed: () {
                            final target = detail ?? DetailMahasiswa(ringkasan: mhs);
                            BagikanProfilSheet.tampilkan(context, mahasiswa: target);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Data Utama 2 Kolom (Sesuai Format PDDikti Resmi)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Data Mahasiswa'.toUpperCase(),
                    style: const TextStyle(
                      color: Warna.kunyit,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),

                Container(
                  decoration: const BoxDecoration(
                    color: Warna.tintaAngkat,
                    border: Border(
                      top: BorderSide(color: Warna.garis, width: 1),
                      bottom: BorderSide(color: Warna.garis, width: 1),
                    ),
                  ),
                  child: Column(
                    children: [
                      _BarisDuaKolom(
                        kiri: _SelData(
                          label: 'Nama',
                          nilai: mhs.nama,
                        ),
                        kanan: _SelData(
                          label: 'Perguruan Tinggi',
                          nilai: mhs.namaPt,
                          warnaNilai: Warna.kunyit,
                        ),
                      ),
                      const Divider(height: 1, color: Warna.garis),
                      _BarisDuaKolom(
                        kiri: _SelData(
                          label: 'Jenis Kelamin',
                          nilai: detail?.jenisKelamin ?? '-',
                        ),
                        kanan: _SelData(
                          label: 'Tanggal Masuk',
                          nilai: formatTglMasuk,
                        ),
                      ),
                      const Divider(height: 1, color: Warna.garis),
                      _BarisDuaKolom(
                        kiri: _SelData(
                          label: 'NIM',
                          nilai: mhs.nim,
                        ),
                        kanan: _SelData(
                          label: 'Jenjang - Program Studi',
                          nilai: detail?.jenjangProdi ?? '${mhs.jenjang} - ${mhs.namaProdi}',
                        ),
                      ),
                      const Divider(height: 1, color: Warna.garis),
                      _BarisDuaKolom(
                        kiri: _SelData(
                          label: 'Status Awal Mahasiswa',
                          nilai: detail?.statusAwal ?? 'Peserta didik baru',
                        ),
                        kanan: _SelData(
                          label: 'Status Terakhir Mahasiswa',
                          nilai: statusRaw ?? '-',
                          warnaNilai: warnaStatus,
                        ),
                      ),
                    ],
                  ),
                ),

                // Biodata Tambahan (Tempat/Tanggal Lahir bila ada)
                if (detail != null &&
                    ((detail.tempatLahir != null && detail.tempatLahir!.isNotEmpty) ||
                     (detail.tanggalLahir != null && detail.tanggalLahir!.isNotEmpty))) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(
                      'Biodata Tambahan'.toUpperCase(),
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
                      color: Warna.tintaAngkat,
                      border: Border(
                        top: BorderSide(color: Warna.garis, width: 1),
                        bottom: BorderSide(color: Warna.garis, width: 1),
                      ),
                    ),
                    child: Column(
                      children: [
                        if (detail.tempatLahir != null && detail.tempatLahir!.isNotEmpty)
                          _BarisInfoTunggal(label: 'Tempat Lahir', nilai: detail.tempatLahir!),
                        if (detail.tanggalLahir != null && detail.tanggalLahir!.isNotEmpty) ...[
                          if (detail.tempatLahir != null && detail.tempatLahir!.isNotEmpty)
                            const Divider(height: 1, color: Warna.garis),
                          _BarisInfoTunggal(
                            label: 'Tanggal Lahir',
                            nilai: FormatTanggal.tanggal(detail.tanggalLahir!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // Data Kelulusan (untuk alumni/mahasiswa lulus)
                if (detail != null &&
                    ((detail.nomorIjazah != null && detail.nomorIjazah!.isNotEmpty) ||
                     (detail.tanggalKeluar != null && detail.tanggalKeluar!.isNotEmpty) ||
                     (detail.tahunKeluar != null && detail.tahunKeluar!.isNotEmpty))) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(
                      'Kelulusan'.toUpperCase(),
                      style: const TextStyle(
                        color: Warna.laut,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: Warna.tintaAngkat,
                      border: Border(
                        top: BorderSide(color: Warna.garis, width: 1),
                        bottom: BorderSide(color: Warna.garis, width: 1),
                      ),
                    ),
                    child: Column(
                      children: [
                        if (detail.nomorIjazah != null && detail.nomorIjazah!.isNotEmpty)
                          _BarisInfoTunggal(label: 'Nomor Ijazah', nilai: detail.nomorIjazah!),
                        if (detail.tanggalKeluar != null && detail.tanggalKeluar!.isNotEmpty) ...[
                          const Divider(height: 1, color: Warna.garis),
                          _BarisInfoTunggal(
                            label: 'Tanggal Keluar / Lulus',
                            nilai: FormatTanggal.tanggal(detail.tanggalKeluar!),
                          ),
                        ],
                        if (detail.tahunKeluar != null && detail.tahunKeluar!.isNotEmpty) ...[
                          const Divider(height: 1, color: Warna.garis),
                          _BarisInfoTunggal(label: 'Tahun Keluar', nilai: detail.tahunKeluar!),
                        ],
                      ],
                    ),
                  ),
                ],

                // Riwayat Perkuliahan
                if (detail != null && detail.riwayatKuliah.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(
                      'Riwayat Perkuliahan (${detail.riwayatKuliah.length} Semester)'.toUpperCase(),
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
                        for (int i = 0; i < detail.riwayatKuliah.length; i++) ...[
                          if (i > 0) const Divider(height: 1, color: Warna.garis),
                          Container(
                            color: Warna.tintaAngkat,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    detail.riwayatKuliah[i].semester,
                                    style: const TextStyle(
                                      color: Warna.kapur,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Warna.garis,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Text(
                                    '${detail.riwayatKuliah[i].sks} SKS',
                                    style: const TextStyle(
                                      color: Warna.kapurRedup,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  detail.riwayatKuliah[i].status,
                                  style: TextStyle(
                                    color: detail.riwayatKuliah[i].status.toLowerCase() == 'aktif'
                                        ? Warna.laut
                                        : Warna.kapurRedup,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
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

class _BarisDuaKolom extends StatelessWidget {
  const _BarisDuaKolom({
    required this.kiri,
    required this.kanan,
  });

  final _SelData kiri;
  final _SelData kanan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: kiri),
          const SizedBox(width: 16),
          Expanded(child: kanan),
        ],
      ),
    );
  }
}

class _SelData extends StatelessWidget {
  const _SelData({
    required this.label,
    required this.nilai,
    this.warnaNilai,
  });

  final String label;
  final String nilai;
  final Color? warnaNilai;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Warna.kapurRedup,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          nilai.isNotEmpty ? nilai : '-',
          style: TextStyle(
            color: warnaNilai ?? Warna.kapur,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _BarisInfoTunggal extends StatelessWidget {
  const _BarisInfoTunggal({required this.label, required this.nilai});
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
