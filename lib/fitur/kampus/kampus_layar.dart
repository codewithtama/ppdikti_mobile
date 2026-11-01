import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/format/angka.dart';
import '../../core/format/status_akademik.dart';
import '../../core/net/sesi_cloudflare.dart';
import '../../core/theme/tokens.dart';
import '../../data/model/kampus.dart';
import '../../data/model/pencarian_global.dart';
import '../../data/repo/kampus_repo.dart';
import '../pencarian/pencarian_vm.dart';
import '../pencarian/verifikasi_cloudflare_sheet.dart';
import 'filter_sheet.dart';
import 'kampus_vm.dart';
import 'logo_kampus.dart';

class KampusLayar extends ConsumerStatefulWidget {
  const KampusLayar({super.key, this.autofokus = false});
  final bool autofokus;

  @override
  ConsumerState<KampusLayar> createState() => _KampusLayarState();
}

class _KampusLayarState extends ConsumerState<KampusLayar> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final qAwal = ref.read(pencarianGlobalProvider).query;
    _textController = TextEditingController(text: qAwal);
    _focusNode = FocusNode();

    if (widget.autofokus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      ref.read(kampusQueryProvider.notifier).perbaruiQ(val);
      ref.read(pencarianGlobalProvider.notifier).aturQuery(val);
    });
  }

  Future<void> _bukaFilterSheet() async {
    final query = ref.read(kampusQueryProvider);
    final dataParsed = ref.read(daftarKampusProvider).value;
    if (dataParsed == null) return;

    final hasil = await showModalBottomSheet<HasilFilterKampus>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterSheet(
        queryAwal: query,
        semuaKampus: dataParsed.daftarKampus,
        aliasMap: dataParsed.aliasMap,
      ),
    );

    if (hasil != null) {
      ref.read(kampusQueryProvider.notifier).perbaruiFilter(
        kelompok: hasil.kelompok,
        pembina: hasil.pembina,
        kota: hasil.kota,
        provinsi: hasil.provinsi,
        akreditasi: hasil.akreditasi,
        status: hasil.status,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final statePencarian = ref.watch(pencarianGlobalProvider);
    final statusUnduhAsync = ref.watch(daftarKampusProvider);
    final queryKampus = ref.watch(kampusQueryProvider);
    final hasilKampus = ref.watch(hasilKampusProvider);
    final sesiCloudflare = ref.watch(sesiCloudflareProvider);
    final totalFilter = queryKampus.totalKategoriFilterAktif;

    final kategori = statePencarian.kategori;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pencarian & Direktori'),
        actions: [
          IconButton(
            icon: Icon(
              sesiCloudflare.terverifikasi
                  ? PhosphorIconsFill.shieldCheck
                  : PhosphorIconsRegular.shieldWarning,
              color: sesiCloudflare.terverifikasi ? Warna.laut : Warna.kunyit,
            ),
            tooltip: sesiCloudflare.terverifikasi
                ? 'Sesi Cloudflare Terverifikasi'
                : 'Verifikasi Cloudflare',
            onPressed: () async {
              final ok = await VerifikasiCloudflareSheet.tampilkan(context);
              if (ok == true && statePencarian.query.isNotEmpty) {
                ref.read(pencarianGlobalProvider.notifier).lakukanPencarian(statePencarian.query);
              }
            },
          ),
          if (kategori == KategoriPencarian.kampus)
            IconButton(
              icon: const Icon(PhosphorIconsRegular.mapTrifold),
              tooltip: 'Buka Peta Kampus',
              onPressed: () => context.push('/peta'),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Verifikasi Cloudflare (jika dibutuhkan)
          if (statePencarian.butuhVerifikasi && !sesiCloudflare.terverifikasi)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Warna.tintaAngkat,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: Warna.kunyit, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(PhosphorIconsFill.shieldWarning, color: Warna.kunyit, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Verifikasi Cloudflare Diperlukan',
                          style: TextStyle(
                            color: Warna.kapur,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          final ok = await VerifikasiCloudflareSheet.tampilkan(context);
                          if (ok == true && statePencarian.query.isNotEmpty) {
                            ref
                                .read(pencarianGlobalProvider.notifier)
                                .lakukanPencarian(statePencarian.query);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Warna.kunyit,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Text(
                            'Verifikasi (1x)',
                            style: TextStyle(
                              color: Warna.tinta,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Server resmi PDDikti meminta verifikasi bot (Turnstile). Selesaikan verifikasi sekali agar Anda bisa mencari data mahasiswa dan dosen secara langsung.',
                    style: TextStyle(color: Warna.kapurRedup, fontSize: 11, height: 1.35),
                  ),
                ],
              ),
            ),

          // Baris Input Pencarian
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                hintText: _getHintText(kategori),
                prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass, size: 20, color: Warna.kapurRedup),
                suffixIcon: _textController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(PhosphorIconsRegular.x, size: 18, color: Warna.kapurRedup),
                        onPressed: () {
                          _textController.clear();
                          ref.read(kampusQueryProvider.notifier).perbaruiQ('');
                          ref.read(pencarianGlobalProvider.notifier).aturQuery('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Kategori Segmented Pills: [ Semua ] [ Kampus ] [ Mahasiswa ] [ Dosen ] [ Program Studi ]
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: KategoriPencarian.values.map((kat) {
                final aktif = kat == kategori;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      ref.read(pencarianGlobalProvider.notifier).aturKategori(kat);
                    },
                    borderRadius: BorderRadius.circular(2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: aktif ? Warna.kunyit : Warna.tintaAngkat,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(
                          color: aktif ? Warna.kunyit : Warna.garis,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        kat.label,
                        style: TextStyle(
                          color: aktif ? Warna.tinta : Warna.kapur,
                          fontSize: 12,
                          fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Baris filter tambahan khusus tab Kampus
          if (kategori == KategoriPencarian.kampus) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ...queryKampus.kelompok.map((kel) => _ChipFilter(
                                label: kel,
                                onHapus: () => ref
                                    .read(kampusQueryProvider.notifier)
                                    .hapusKelompokTertentu(kel),
                              )),
                          ...queryKampus.provinsi.map((pr) => _ChipFilter(
                                label: pr,
                                onHapus: () => ref
                                    .read(kampusQueryProvider.notifier)
                                    .hapusProvinsiTertentu(pr),
                              )),
                          ...queryKampus.akreditasi.map((ak) => _ChipFilter(
                                label: ak,
                                onHapus: () => ref
                                    .read(kampusQueryProvider.notifier)
                                    .hapusAkreditasiTertentu(ak),
                              )),
                          ...queryKampus.status.map((st) => _ChipFilter(
                                label: st,
                                onHapus: () => ref
                                    .read(kampusQueryProvider.notifier)
                                    .hapusStatusTertentu(st),
                              )),
                          ...queryKampus.pembina.map((pem) => _ChipFilter(
                                label: pem,
                                onHapus: () => ref
                                    .read(kampusQueryProvider.notifier)
                                    .hapusPembinaTertentu(pem),
                              )),
                          ...queryKampus.kota.map((kota) => _ChipFilter(
                                label: kota,
                                onHapus: () => ref
                                    .read(kampusQueryProvider.notifier)
                                    .hapusKotaTertentu(kota),
                              )),
                        ],
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _bukaFilterSheet,
                    style: TextButton.styleFrom(
                      foregroundColor: totalFilter > 0 ? Warna.kunyit : Warna.kapur,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(PhosphorIconsRegular.faders, size: 18),
                    label: Text(totalFilter > 0 ? 'Filter $totalFilter' : 'Filter'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: Text(
                '${FormatAngka.ribuan(hasilKampus.daftar.length)} dari ${FormatAngka.ribuan(hasilKampus.totalKampus)} kampus',
                style: Gaya.catatan,
              ),
            ),
          ],

          const Divider(height: 1, color: Warna.garis),

          // Konten Utama berdasarkan Kategori
          Expanded(
            child: _buildKontenUtama(
              context: context,
              kategori: kategori,
              statePencarian: statePencarian,
              statusUnduhAsync: statusUnduhAsync,
              hasilKampus: hasilKampus,
            ),
          ),
        ],
      ),
    );
  }

  String _getHintText(KategoriPencarian kat) {
    switch (kat) {
      case KategoriPencarian.semua:
        return 'Cari mahasiswa, dosen, kampus, prodi...';
      case KategoriPencarian.kampus:
        return 'Cari nama kampus, kode, atau kota';
      case KategoriPencarian.mahasiswa:
        return 'Cari nama mahasiswa atau NIM';
      case KategoriPencarian.dosen:
        return 'Cari nama dosen atau NIDN';
      case KategoriPencarian.prodi:
        return 'Cari nama program studi atau jenjang';
    }
  }

  Widget _buildKontenUtama({
    required BuildContext context,
    required KategoriPencarian kategori,
    required StatePencarianGlobal statePencarian,
    required AsyncValue<DataParsedKampus> statusUnduhAsync,
    required HasilKampus hasilKampus,
  }) {
    if (kategori == KategoriPencarian.kampus) {
      return _buildDaftarKampus(statusUnduhAsync, hasilKampus);
    }

    if (statePencarian.sedangMemuat) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Warna.kunyit, strokeWidth: 2),
            SizedBox(height: 12),
            Text('Mencari data PDDikti...', style: TextStyle(color: Warna.kapurRedup)),
          ],
        ),
      );
    }

    final q = statePencarian.query.trim();

    if (q.isEmpty) {
      return _buildStateAwal(kategori);
    }

    final hasil = statePencarian.hasil;

    switch (kategori) {
      case KategoriPencarian.mahasiswa:
        return _buildDaftarMahasiswa(hasil.mahasiswa);
      case KategoriPencarian.dosen:
        return _buildDaftarDosen(hasil.dosen);
      case KategoriPencarian.prodi:
        return _buildDaftarProdi(hasil.prodi);
      case KategoriPencarian.semua:
        return _buildHasilSemua(hasil);
      case KategoriPencarian.kampus:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStateAwal(KategoriPencarian kat) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pencarian Data Pangkalan Pendidikan Tinggi'.toUpperCase(),
            style: const TextStyle(
              color: Warna.kunyit,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cari rekam jejak mahasiswa, keaktifan dosen, status program studi, atau perguruan tinggi se-Indonesia.',
            style: TextStyle(
              color: Warna.kapurRedup,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Contoh pencarian populer:',
            style: TextStyle(
              color: Warna.kapur,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ChipSaran(teks: 'Budi Santoso', onTap: () => _pilihSaran('Budi Santoso')),
              _ChipSaran(teks: 'Informatika', onTap: () => _pilihSaran('Informatika')),
              _ChipSaran(teks: 'Siti Nurhaliza', onTap: () => _pilihSaran('Siti Nurhaliza')),
              _ChipSaran(teks: 'Universitas Indonesia', onTap: () => _pilihSaran('Universitas Indonesia')),
              _ChipSaran(teks: 'Institut Teknologi Bandung', onTap: () => _pilihSaran('Institut Teknologi Bandung')),
              _ChipSaran(teks: 'Kedokteran', onTap: () => _pilihSaran('Kedokteran')),
              _ChipSaran(teks: 'Ahmad', onTap: () => _pilihSaran('Ahmad')),
            ],
          ),
        ],
      ),
    );
  }

  void _pilihSaran(String teks) {
    _textController.text = teks;
    _onQueryChanged(teks);
  }

  Widget _buildDaftarMahasiswa(List<HasilMahasiswa> list) {
    if (list.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Mahasiswa tidak ditemukan.\nPeriksa ejaan nama atau Nomor Induk Mahasiswa (NIM).',
            textAlign: TextAlign.center,
            style: TextStyle(color: Warna.kapurRedup, height: 1.4),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (context, index) => const Divider(height: 1, color: Warna.garis),
      itemBuilder: (context, index) {
        final mhs = list[index];
        return _BarisMahasiswa(mhs: mhs);
      },
    );
  }

  Widget _buildDaftarDosen(List<HasilDosen> list) {
    if (list.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Dosen tidak ditemukan.\nPeriksa ejaan nama dosen atau NIDN/NUP.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Warna.kapurRedup, height: 1.4),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (context, index) => const Divider(height: 1, color: Warna.garis),
      itemBuilder: (context, index) {
        final dsn = list[index];
        return _BarisDosen(dsn: dsn);
      },
    );
  }

  Widget _buildDaftarProdi(List<HasilProdi> list) {
    if (list.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Program studi tidak ditemukan.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Warna.kapurRedup),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (context, index) => const Divider(height: 1, color: Warna.garis),
      itemBuilder: (context, index) {
        final prodi = list[index];
        return _BarisProdi(prodi: prodi);
      },
    );
  }

  Widget _buildHasilSemua(HasilPencarianGlobal hasil) {
    if (hasil.kosong) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Tidak ada hasil ditemukan di PDDikti.\nCoba gunakan kata kunci nama atau institusi lain.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Warna.kapurRedup, height: 1.4),
          ),
        ),
      );
    }

    return ListView(
      children: [
        if (hasil.mahasiswa.isNotEmpty) ...[
          _HeaderGrup(
            judul: 'Mahasiswa (${hasil.mahasiswa.length})',
            onLihatSemua: () => ref
                .read(pencarianGlobalProvider.notifier)
                .aturKategori(KategoriPencarian.mahasiswa),
          ),
          for (final mhs in hasil.mahasiswa.take(4)) ...[
            _BarisMahasiswa(mhs: mhs),
            const Divider(height: 1, color: Warna.garis),
          ],
        ],
        if (hasil.dosen.isNotEmpty) ...[
          _HeaderGrup(
            judul: 'Dosen (${hasil.dosen.length})',
            onLihatSemua: () => ref
                .read(pencarianGlobalProvider.notifier)
                .aturKategori(KategoriPencarian.dosen),
          ),
          for (final dsn in hasil.dosen.take(4)) ...[
            _BarisDosen(dsn: dsn),
            const Divider(height: 1, color: Warna.garis),
          ],
        ],
        if (hasil.prodi.isNotEmpty) ...[
          _HeaderGrup(
            judul: 'Program Studi (${hasil.prodi.length})',
            onLihatSemua: () => ref
                .read(pencarianGlobalProvider.notifier)
                .aturKategori(KategoriPencarian.prodi),
          ),
          for (final prodi in hasil.prodi.take(4)) ...[
            _BarisProdi(prodi: prodi),
            const Divider(height: 1, color: Warna.garis),
          ],
        ],
        if (hasil.pt.isNotEmpty) ...[
          _HeaderGrup(
            judul: 'Perguruan Tinggi (${hasil.pt.length})',
            onLihatSemua: () => ref
                .read(pencarianGlobalProvider.notifier)
                .aturKategori(KategoriPencarian.kampus),
          ),
          for (final kampus in hasil.pt.take(4)) ...[
            _BarisKampusItem(kampus: kampus),
            const Divider(height: 1, color: Warna.garis),
          ],
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildDaftarKampus(
    AsyncValue<DataParsedKampus> statusUnduhAsync,
    HasilKampus hasilKampus,
  ) {
    return statusUnduhAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Menyiapkan direktori kampus...', style: TextStyle(color: Warna.kapurRedup)),
        ),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Daftar kampus belum bisa dimuat.',
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
      ),
      data: (_) {
        if (hasilKampus.daftar.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Tidak ada kampus yang cocok dengan filter atau kata kunci.',
                style: Gaya.catatan,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.separated(
          itemCount: hasilKampus.daftar.length,
          separatorBuilder: (context, index) => const Divider(height: 1, color: Warna.garis),
          itemBuilder: (context, index) {
            final kampus = hasilKampus.daftar[index];
            return _BarisKampusItem(kampus: kampus);
          },
        );
      },
    );
  }
}

class _HeaderGrup extends StatelessWidget {
  const _HeaderGrup({required this.judul, required this.onLihatSemua});
  final String judul;
  final VoidCallback onLihatSemua;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Warna.tinta,
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            judul.toUpperCase(),
            style: const TextStyle(
              color: Warna.kunyit,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          TextButton(
            onPressed: onLihatSemua,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Semua', style: TextStyle(fontSize: 12, color: Warna.kapurRedup)),
                SizedBox(width: 4),
                Icon(PhosphorIconsRegular.caretRight, size: 14, color: Warna.kapurRedup),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarisMahasiswa extends StatelessWidget {
  const _BarisMahasiswa({required this.mhs});
  final HasilMahasiswa mhs;

  @override
  Widget build(BuildContext context) {
    final statusRaw = mhs.status;
    final labelStatus = StatusAkademikHelper.ringkasStatus(statusRaw);
    final warnaBadge = StatusAkademikHelper.warnaTeks(statusRaw);

    return InkWell(
      onTap: () {
        context.push('/mahasiswa/${mhs.id}', extra: mhs);
      },
      child: Container(
        color: Warna.tinta,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    mhs.nama,
                    style: const TextStyle(
                      color: Warna.kapur,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (labelStatus.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: warnaBadge.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: warnaBadge.withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      labelStatus,
                      style: TextStyle(
                        color: warnaBadge,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'NIM: ${mhs.nim}',
                  style: const TextStyle(
                    color: Warna.kapurRedup,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '·',
                  style: TextStyle(color: Warna.kapurRedup.withValues(alpha: 0.5)),
                ),
                const SizedBox(width: 8),
                Text(
                  mhs.jenjang,
                  style: const TextStyle(
                    color: Warna.kunyit,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${mhs.namaProdi} · ${mhs.singkatanPt ?? mhs.namaPt}',
              style: const TextStyle(
                color: Warna.kapurRedup,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _BarisDosen extends StatelessWidget {
  const _BarisDosen({required this.dsn});
  final HasilDosen dsn;

  @override
  Widget build(BuildContext context) {
    final statusRaw = dsn.status;
    final labelStatus = StatusAkademikHelper.ringkasStatus(statusRaw);
    final warnaBadge = StatusAkademikHelper.warnaTeks(statusRaw);

    return InkWell(
      onTap: () {
        context.push('/dosen/${dsn.id}', extra: dsn);
      },
      child: Container(
        color: Warna.tinta,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    dsn.nama,
                    style: const TextStyle(
                      color: Warna.kapur,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (labelStatus.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: warnaBadge.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: warnaBadge.withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      labelStatus,
                      style: TextStyle(
                        color: warnaBadge,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'NIDN: ${dsn.nidn.isNotEmpty ? dsn.nidn : "-"}',
              style: const TextStyle(
                color: Warna.kapurRedup,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${dsn.namaProdi} · ${dsn.singkatanPt ?? dsn.namaPt}',
              style: const TextStyle(
                color: Warna.kapurRedup,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _BarisProdi extends StatelessWidget {
  const _BarisProdi({required this.prodi});
  final HasilProdi prodi;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.push('/prodi/${prodi.id}', extra: prodi);
      },
      child: Container(
        color: Warna.tinta,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Warna.garis,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    prodi.jenjang,
                    style: const TextStyle(
                      color: Warna.kunyit,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    prodi.nama,
                    style: const TextStyle(
                      color: Warna.kapur,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Warna.laut.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    prodi.akreditasi,
                    style: const TextStyle(
                      color: Warna.laut,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              prodi.pt,
              style: const TextStyle(
                color: Warna.kapurRedup,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _BarisKampusItem extends StatelessWidget {
  const _BarisKampusItem({required this.kampus});
  final Kampus kampus;

  Color _warnaStatus(String status) {
    final st = status.toLowerCase();
    if (st.contains('aktif') && !st.contains('non')) return const Color(0xFF22C55E);
    if (st.contains('alih')) return const Color(0xFF3B82F6);
    if (st.contains('tutup')) return const Color(0xFFEF4444);
    if (st.contains('bina')) return const Color(0xFFF59E0B);
    return Warna.kunyit;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _warnaStatus(kampus.status);
    final lokasi = [
      kampus.kota,
      if (kampus.provinsi != null && kampus.provinsi != 'Lainnya') 'Prov. ${kampus.provinsi}',
    ].where((s) => s != null && s.isNotEmpty && s != 'Tidak Diisi').join(', ');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Warna.tintaAngkat,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Warna.garis, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.push('/kampus/${kampus.kode}');
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris Atas: Logo Kampus, Nama, dan Badge Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LogoKampus(idSp: kampus.idSp, nama: kampus.nama, ukuran: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kampus.nama,
                          style: const TextStyle(
                            color: Warna.kapur,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: statusColor, width: 1),
                              ),
                              child: Text(
                                kampus.status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              kampus.kode,
                              style: const TextStyle(
                                color: Warna.kapurRedup,
                                fontSize: 11.5,
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
              const SizedBox(height: 10),

              // Lokasi Kampus
              if (lokasi.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(PhosphorIconsRegular.mapPin, size: 14, color: Warna.kapurRedup),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        lokasi,
                        style: const TextStyle(
                          color: Warna.kapurRedup,
                          fontSize: 12.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Info Chips Baris (Akreditasi, Kelompok / Program Studi)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _BadgeInfoMini(
                    icon: PhosphorIconsRegular.certificate,
                    label: kampus.akreditasi.isNotEmpty ? kampus.akreditasi : 'Terakreditasi',
                    warna: Warna.kunyit,
                  ),
                  _BadgeInfoMini(
                    icon: PhosphorIconsRegular.books,
                    label: kampus.kelompok,
                    warna: Warna.laut,
                  ),
                  if (kampus.pembina.isNotEmpty)
                    _BadgeInfoMini(
                      icon: PhosphorIconsRegular.buildings,
                      label: kampus.pembina,
                      warna: Warna.kapurRedup,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Warna.garis, height: 1),
              const SizedBox(height: 8),

              // Baris Aksi Bawah: Lihat Detail & Pin Peta
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        context.push('/kampus/${kampus.kode}');
                      },
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        side: const BorderSide(color: Warna.garisTegas),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                      child: const Text('Lihat Detail', style: TextStyle(fontSize: 12.5)),
                    ),
                  ),
                  if (kampus.koordinat != null) ...[
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      icon: const Icon(PhosphorIconsRegular.mapPin, size: 16, color: Warna.kunyit),
                      tooltip: 'Lihat di peta',
                      style: IconButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        side: const BorderSide(color: Warna.garisTegas),
                      ),
                      onPressed: () => context.push('/peta?kode=${kampus.kode}'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeInfoMini extends StatelessWidget {
  const _BadgeInfoMini({
    required this.icon,
    required this.label,
    required this.warna,
  });

  final IconData icon;
  final String label;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: warna.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: warna),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: warna,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipSaran extends StatelessWidget {
  const _ChipSaran({required this.teks, required this.onTap});
  final String teks;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Warna.tintaAngkat,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: Warna.garis, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(PhosphorIconsRegular.magnifyingGlass, size: 13, color: Warna.kunyit),
            const SizedBox(width: 6),
            Text(
              teks,
              style: const TextStyle(
                color: Warna.kapur,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipFilter extends StatelessWidget {
  const _ChipFilter({required this.label, required this.onHapus});
  final String label;
  final VoidCallback onHapus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        onDeleted: onHapus,
        backgroundColor: Warna.tintaAngkat,
        side: const BorderSide(color: Warna.garis, width: 1),
        labelStyle: Gaya.catatan.copyWith(color: Warna.kunyit),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
