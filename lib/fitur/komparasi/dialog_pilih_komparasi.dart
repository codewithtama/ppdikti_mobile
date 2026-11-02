import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/tokens.dart';
import '../kampus/kampus_vm.dart';
import '../kampus/logo_kampus.dart';
import 'komparasi_vm.dart';

class DialogPilihKomparasiKampus extends ConsumerStatefulWidget {
  const DialogPilihKomparasiKampus({super.key});

  static Future<void> tampilkan(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DialogPilihKomparasiKampus(),
    );
  }

  @override
  ConsumerState<DialogPilihKomparasiKampus> createState() =>
      _DialogPilihKomparasiKampusState();
}

class _DialogPilihKomparasiKampusState
    extends ConsumerState<DialogPilihKomparasiKampus> {
  final TextEditingController _cariCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _cariCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(daftarKampusProvider);
    final stateKomparasi = ref.watch(komparasiProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Warna.tinta,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: Warna.garis, width: 1)),
      ),
      child: Column(
        children: [
          // Drag Handle & Header
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Warna.garisTegas,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tambah Kampus untuk Komparasi',
                  style: TextStyle(
                    color: Warna.kapur,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.x, size: 20, color: Warna.kapurRedup),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Kolom Input Pencarian
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: TextField(
              controller: _cariCtrl,
              onChanged: (val) => setState(() => _query = val.trim().toLowerCase()),
              style: const TextStyle(color: Warna.kapur, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Ketik nama kampus atau kode PT...',
                hintStyle: const TextStyle(color: Warna.kapurRedup, fontSize: 13.5),
                prefixIcon: const Icon(
                  PhosphorIconsRegular.magnifyingGlass,
                  size: 18,
                  color: Warna.kunyit,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(PhosphorIconsRegular.x, size: 16, color: Warna.kapurRedup),
                        onPressed: () {
                          _cariCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Warna.tintaAngkat,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Warna.garis),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Warna.garis),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Warna.kunyit),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1, color: Warna.garis),

          // Daftar Kampus
          Expanded(
            child: asyncData.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Warna.kunyit),
              ),
              error: (err, _) => Center(
                child: Text('Gagal memuat daftar kampus.', style: Gaya.isi),
              ),
              data: (data) {
                final semua = data.daftarKampus;
                final filtered = _query.isEmpty
                    ? semua.take(40).toList()
                    : semua
                        .where((k) =>
                            k.nama.toLowerCase().contains(_query) ||
                            k.kode.toLowerCase().contains(_query) ||
                            (k.kota != null && k.kota!.toLowerCase().contains(_query)))
                        .take(50)
                        .toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Tidak ada kampus yang cocok dengan pencarian.',
                        style: TextStyle(color: Warna.kapurRedup),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, index) => const Divider(height: 1, color: Warna.garis),
                  itemBuilder: (context, index) {
                    final kampus = filtered[index];
                    final sudahDipilih = stateKomparasi.apakahKampusAda(kampus.kode);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      leading: LogoKampus(idSp: kampus.idSp, nama: kampus.nama, ukuran: 38),
                      title: Text(
                        kampus.nama,
                        style: const TextStyle(
                          color: Warna.kapur,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Kode ${kampus.kode} • ${kampus.kelompok} • ${kampus.kota ?? kampus.provinsi ?? "Indonesia"}',
                          style: const TextStyle(color: Warna.kapurRedup, fontSize: 11.5),
                        ),
                      ),
                      trailing: sudahDipilih
                          ? IconButton(
                              icon: const Icon(PhosphorIconsFill.checkCircle, color: Warna.kunyit, size: 24),
                              tooltip: 'Hapus dari komparasi',
                              onPressed: () {
                                ref.read(komparasiProvider.notifier).hapusKampus(kampus.kode);
                              },
                            )
                          : IconButton(
                              icon: const Icon(PhosphorIconsRegular.plusCircle, color: Warna.kapurRedup, size: 24),
                              tooltip: 'Tambah ke komparasi',
                              onPressed: () {
                                final berhasil = ref
                                    .read(komparasiProvider.notifier)
                                    .tambahKampus(kampus);
                                if (!berhasil) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Maksimal komparasi 3 kampus sekaligus'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                            ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
