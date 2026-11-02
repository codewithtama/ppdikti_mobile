import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/tokens.dart';
import '../kampus/logo_kampus.dart';
import 'dialog_pilih_komparasi.dart';
import 'komparasi_model.dart';
import 'komparasi_vm.dart';

enum TabKomparasi { kampus, prodi }

class KomparasiLayar extends ConsumerStatefulWidget {
  const KomparasiLayar({super.key});

  @override
  ConsumerState<KomparasiLayar> createState() => _KomparasiLayarState();
}

class _KomparasiLayarState extends ConsumerState<KomparasiLayar> {
  TabKomparasi _tab = TabKomparasi.kampus;

  Color _warnaAkreditasi(String a) {
    final ak = a.toLowerCase();
    if (ak.contains('unggul') || ak == 'a') return Warna.kunyit;
    if (ak.contains('baik sekali') || ak == 'b') return Warna.laut;
    if (ak.contains('baik') || ak == 'c') return const Color(0xFF60A5FA);
    return Warna.kapurRedup;
  }

  void _bagikanKomparasi(KomparasiState state) {
    final sb = StringBuffer();
    sb.writeln('📊 *HASIL KOMPARASI RESMI PERGURUAN TINGGI (PDDIKTI)*');
    sb.writeln('Sumber: Pangkalan Data Pendidikan Tinggi - Kemdiktisaintek RI');
    sb.writeln('-----------------------------------------------\n');

    if (_tab == TabKomparasi.kampus) {
      if (state.daftarKampus.isEmpty) return;
      for (int i = 0; i < state.daftarKampus.length; i++) {
        final k = state.daftarKampus[i];
        sb.writeln('${i + 1}. *${k.nama}* (Kode PT: ${k.kode})');
        sb.writeln('   • Jenis/Kelompok: ${k.kelompok}');
        sb.writeln('   • Akreditasi: ${k.akreditasi.isNotEmpty ? k.akreditasi : "-"}');
        sb.writeln('   • Rasio Dosen : Mhs: ${k.rasioDosen ?? "-"}');
        sb.writeln('   • Kisaran Biaya: ${k.biayaKuliah ?? "-"}');
        sb.writeln('   • Total Prodi: ${k.jumlahProdi != null ? "${k.jumlahProdi} Program Studi" : "-"}');
        sb.writeln('   • Wilayah: ${k.kota ?? k.provinsi ?? "-"}');
        sb.writeln('');
      }
    } else {
      if (state.daftarProdi.isEmpty) return;
      for (int i = 0; i < state.daftarProdi.length; i++) {
        final p = state.daftarProdi[i];
        sb.writeln('${i + 1}. *${p.jenjang} ${p.nama}*');
        sb.writeln('   • Kampus: ${p.pt}');
        sb.writeln('   • Akreditasi: ${p.akreditasi.isNotEmpty ? p.akreditasi : "-"}');
        sb.writeln('   • Status: ${p.status}');
        sb.writeln('   • Rasio Dosen : Mhs: ${p.rasioDosenMahasiswa ?? "-"}');
        sb.writeln('');
      }
    }

    sb.writeln('Aplikasi PDDikti Mobile: https://github.com/codewithtama/ppdikti_mobile');

    SharePlus.instance.share(
      ShareParams(
        text: sb.toString(),
        subject: 'Hasil Komparasi PDDikti',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(komparasiProvider);
    final adaKampus = state.daftarKampus.isNotEmpty;
    final adaProdi = state.daftarProdi.isNotEmpty;

    return Scaffold(
      backgroundColor: Warna.tinta,
      appBar: AppBar(
        title: const Text('Komparasi Berdampingan'),
        backgroundColor: Warna.tinta,
        elevation: 0,
        actions: [
          if ((_tab == TabKomparasi.kampus && adaKampus) ||
              (_tab == TabKomparasi.prodi && adaProdi)) ...[
            IconButton(
              icon: const Icon(PhosphorIconsRegular.shareNetwork),
              tooltip: 'Bagikan Hasil Komparasi',
              onPressed: () => _bagikanKomparasi(state),
            ),
            IconButton(
              icon: const Icon(PhosphorIconsRegular.trash),
              tooltip: 'Kosongkan Komparasi',
              onPressed: () {
                if (_tab == TabKomparasi.kampus) {
                  ref.read(komparasiProvider.notifier).bersihkanKampus();
                } else {
                  ref.read(komparasiProvider.notifier).bersihkanProdi();
                }
              },
            ),
          ],
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tab Switcher Kampus vs Program Studi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: const BoxDecoration(
              color: Warna.tintaAngkat,
              border: Border(bottom: BorderSide(color: Warna.garis, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _tab = TabKomparasi.kampus),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _tab == TabKomparasi.kampus ? Warna.tinta : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: _tab == TabKomparasi.kampus
                            ? Border.all(color: Warna.kunyit, width: 1.2)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Perguruan Tinggi (${state.daftarKampus.length}/3)',
                        style: TextStyle(
                          color: _tab == TabKomparasi.kampus ? Warna.kunyit : Warna.kapurRedup,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _tab = TabKomparasi.prodi),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _tab == TabKomparasi.prodi ? Warna.tinta : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: _tab == TabKomparasi.prodi
                            ? Border.all(color: Warna.kunyit, width: 1.2)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Program Studi (${state.daftarProdi.length}/3)',
                        style: TextStyle(
                          color: _tab == TabKomparasi.prodi ? Warna.kunyit : Warna.kapurRedup,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Area Konten Matriks
          Expanded(
            child: _tab == TabKomparasi.kampus
                ? _buildKontenKampus(state)
                : _buildKontenProdi(state),
          ),
        ],
      ),
    );
  }

  Widget _buildKontenKampus(KomparasiState state) {
    if (state.daftarKampus.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Warna.tintaAngkat,
                  shape: BoxShape.circle,
                  border: Border.all(color: Warna.garis, width: 1),
                ),
                child: const Icon(PhosphorIconsRegular.scales, size: 48, color: Warna.kunyit),
              ),
              const SizedBox(height: 20),
              const Text(
                'Belum Ada Kampus yang Dipilih',
                style: TextStyle(
                  color: Warna.kapur,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Pilih hingga 3 kampus untuk membandingkan akreditasi, rasio dosen-mahasiswa, biaya kuliah, dan jumlah prodi secara berdampingan.',
                style: TextStyle(color: Warna.kapurRedup, fontSize: 13, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(PhosphorIconsRegular.plus, size: 16),
                label: const Text('Pilih Kampus Sekarang'),
                onPressed: () => DialogPilihKomparasiKampus.tampilkan(context),
              ),
            ],
          ),
        ),
      );
    }

    final kolomList = List<ItemKomparasiKampus>.from(state.daftarKampus);
    final bisaTambah = state.bisaTambahKampus;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kartu Header Kolom Kampus
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...kolomList.map((k) => _buildHeaderKartuKampus(k)),
                if (bisaTambah) _buildKartuTambahKampus(),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tabel Baris Matriks Indikator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Warna.tintaAngkat,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Warna.garis, width: 1),
              ),
              child: Column(
                children: [
                  _buildBarisMatriks(
                    judul: 'Akreditasi Perguruan Tinggi',
                    nilai: kolomList.map((k) => k.akreditasi.isNotEmpty ? k.akreditasi : '-').toList(),
                    warnaKustom: (val) => _warnaAkreditasi(val),
                  ),
                  _buildBarisMatriks(
                    judul: 'Rasio Dosen : Mahasiswa',
                    nilai: kolomList.map((k) => k.rasioDosen ?? 'Memuat...').toList(),
                  ),
                  _buildBarisMatriks(
                    judul: 'Kisaran Biaya Kuliah (UKT)',
                    nilai: kolomList.map((k) => k.biayaKuliah ?? '-').toList(),
                  ),
                  _buildBarisMatriks(
                    judul: 'Jumlah Program Studi',
                    nilai: kolomList.map((k) => k.jumlahProdi != null ? '${k.jumlahProdi} Prodi' : '-').toList(),
                  ),
                  _buildBarisMatriks(
                    judul: 'Kelompok / Jenis PT',
                    nilai: kolomList.map((k) => k.kelompok.isNotEmpty ? k.kelompok : '-').toList(),
                  ),
                  _buildBarisMatriks(
                    judul: 'Instansi Pembina',
                    nilai: kolomList.map((k) => k.pembina.isNotEmpty ? k.pembina : '-').toList(),
                  ),
                  _buildBarisMatriks(
                    judul: 'Kota / Wilayah',
                    nilai: kolomList.map((k) => k.kota ?? k.provinsi ?? '-').toList(),
                  ),
                  _buildBarisMatriks(
                    judul: 'Status Keaktifan',
                    nilai: kolomList.map((k) => k.status).toList(),
                    warnaKustom: (val) => val.toLowerCase().contains('aktif') ? Warna.laut : Warna.karang,
                  ),
                  _buildBarisMatriks(
                    judul: 'Tanggal Berdiri',
                    nilai: kolomList.map((k) => k.tglBerdiri ?? '-').toList(),
                    garisBawah: false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderKartuKampus(ItemKomparasiKampus k) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Warna.tintaAngkat,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Warna.garis, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                k.kode,
                style: const TextStyle(
                  color: Warna.kapurRedup,
                  fontSize: 10.5,
                  fontFamily: 'monospace',
                ),
              ),
              InkWell(
                onTap: () {
                  ref.read(komparasiProvider.notifier).hapusKampus(k.kode);
                },
                child: const Icon(PhosphorIconsRegular.xCircle, size: 18, color: Warna.karang),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LogoKampus(idSp: k.idSp, nama: k.nama, ukuran: 52),
          const SizedBox(height: 10),
          Text(
            k.nama,
            style: const TextStyle(
              color: Warna.kapur,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => context.push('/kampus/${k.kode}'),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              side: const BorderSide(color: Warna.garisTegas),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            child: const Text('Buka Profil', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildKartuTambahKampus() {
    return InkWell(
      onTap: () => DialogPilihKomparasiKampus.tampilkan(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 140,
        height: 185,
        decoration: BoxDecoration(
          color: Warna.tinta,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Warna.kunyit.withValues(alpha: 0.6), style: BorderStyle.solid, width: 1.2),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIconsRegular.plusCircle, size: 36, color: Warna.kunyit),
            SizedBox(height: 10),
            Text(
              'Tambah\nKampus',
              style: TextStyle(
                color: Warna.kunyit,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKontenProdi(KomparasiState state) {
    if (state.daftarProdi.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Warna.tintaAngkat,
                  shape: BoxShape.circle,
                  border: Border.all(color: Warna.garis, width: 1),
                ),
                child: const Icon(PhosphorIconsRegular.books, size: 48, color: Warna.kunyit),
              ),
              const SizedBox(height: 20),
              const Text(
                'Belum Ada Program Studi Dipilih',
                style: TextStyle(
                  color: Warna.kapur,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Pilih hingga 3 program studi dari halaman Detail Kampus atau Pencarian untuk membandingkan jenjang, akreditasi, dan status keaktifan.',
                style: TextStyle(color: Warna.kapurRedup, fontSize: 13, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(PhosphorIconsRegular.magnifyingGlass, size: 16),
                label: const Text('Buka Pencarian Prodi'),
                onPressed: () => context.go('/kampus'),
              ),
            ],
          ),
        ),
      );
    }

    final listProdi = state.daftarProdi;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Kartu Prodi
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: listProdi.map((p) {
                return Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Warna.tintaAngkat,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Warna.garis, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Warna.kunyit.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Warna.kunyit, width: 0.8),
                            ),
                            child: Text(
                              p.jenjang,
                              style: const TextStyle(
                                color: Warna.kunyit,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              ref.read(komparasiProvider.notifier).hapusProdi(p.id);
                            },
                            child: const Icon(PhosphorIconsRegular.xCircle, size: 18, color: Warna.karang),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        p.nama,
                        style: const TextStyle(
                          color: Warna.kapur,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        p.pt,
                        style: const TextStyle(color: Warna.kapurRedup, fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Matriks Indikator Prodi
          Container(
            decoration: BoxDecoration(
              color: Warna.tintaAngkat,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Warna.garis, width: 1),
            ),
            child: Column(
              children: [
                _buildBarisMatriks(
                  judul: 'Jenjang Pendidikan',
                  nilai: listProdi.map((p) => p.jenjang).toList(),
                ),
                _buildBarisMatriks(
                  judul: 'Akreditasi Program Studi',
                  nilai: listProdi.map((p) => p.akreditasi.isNotEmpty ? p.akreditasi : '-').toList(),
                  warnaKustom: (val) => _warnaAkreditasi(val),
                ),
                _buildBarisMatriks(
                  judul: 'Perguruan Tinggi Penyelenggara',
                  nilai: listProdi.map((p) => p.pt).toList(),
                ),
                _buildBarisMatriks(
                  judul: 'Status Keaktifan Prodi',
                  nilai: listProdi.map((p) => p.status).toList(),
                  warnaKustom: (val) => val.toLowerCase().contains('aktif') ? Warna.laut : Warna.karang,
                ),
                _buildBarisMatriks(
                  judul: 'Rasio Dosen : Mahasiswa',
                  nilai: listProdi.map((p) => p.rasioDosenMahasiswa ?? '-').toList(),
                  garisBawah: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarisMatriks({
    required String judul,
    required List<String> nilai,
    Color Function(String)? warnaKustom,
    bool garisBawah = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: garisBawah
            ? const Border(bottom: BorderSide(color: Warna.garis, width: 1))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            judul.toUpperCase(),
            style: const TextStyle(
              color: Warna.kapurRedup,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: nilai.map((val) {
                final warna = warnaKustom != null ? warnaKustom(val) : Warna.kapur;
                return Container(
                  width: 170,
                  margin: const EdgeInsets.only(right: 12),
                  child: Text(
                    val,
                    style: TextStyle(
                      color: warna,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
