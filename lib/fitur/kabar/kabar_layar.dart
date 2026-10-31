import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/format/tanggal.dart';
import '../../core/theme/tokens.dart';
import 'pengumuman_detail_layar.dart';
import 'pengumuman_vm.dart';
import 'publikasi_vm.dart';
import 'tautan_keluar_sheet.dart';

enum TabKabar { pengumuman, publikasi }

class KabarLayar extends ConsumerStatefulWidget {
  const KabarLayar({super.key});

  @override
  ConsumerState<KabarLayar> createState() => _KabarLayarState();
}

class _KabarLayarState extends ConsumerState<KabarLayar> {
  TabKabar _tabAktif = TabKabar.pengumuman;
  late final TextEditingController _searchController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (_tabAktif == TabKabar.pengumuman) {
        ref.read(pengumumanProvider.notifier).cari(val);
      } else {
        ref.read(publikasiProvider.notifier).cari(val);
      }
    });
  }

  void _gantiTab(TabKabar tab) {
    if (_tabAktif == tab) return;
    setState(() {
      _tabAktif = tab;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kabar'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Navigasi Tab Pengumuman / Publikasi (Garis Bawah Kunyit 2dp, Bukan Pil)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Warna.garis, width: 1)),
            ),
            child: Row(
              children: [
                _TabItem(
                  judul: 'Pengumuman',
                  aktif: _tabAktif == TabKabar.pengumuman,
                  onTap: () => _gantiTab(TabKabar.pengumuman),
                ),
                const SizedBox(width: 24),
                _TabItem(
                  judul: 'Publikasi',
                  aktif: _tabAktif == TabKabar.publikasi,
                  onTap: () => _gantiTab(TabKabar.publikasi),
                ),
              ],
            ),
          ),

          // Baris Input Pencarian
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: _tabAktif == TabKabar.pengumuman
                    ? 'Cari pengumuman'
                    : 'Cari publikasi',
                prefixIcon: const Icon(Icons.search, size: 20, color: Warna.kapurRedup),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 20, color: Warna.kapurRedup),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          const Divider(height: 1),

          // Konten List
          Expanded(
            child: _tabAktif == TabKabar.pengumuman
                ? const _DaftarPengumuman()
                : const _DaftarPublikasi(),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.judul,
    required this.aktif,
    required this.onTap,
  });

  final String judul;
  final bool aktif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: aktif ? Warna.kunyit : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          judul,
          style: Gaya.tombol.copyWith(
            color: aktif ? Warna.kunyit : Warna.kapurRedup,
          ),
        ),
      ),
    );
  }
}

class _DaftarPengumuman extends ConsumerWidget {
  const _DaftarPengumuman();

  String _ambilDuaBaris(String rawHtml) {
    final teks = rawHtml
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return teks;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(pengumumanProvider);

    return stateAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Memuat pengumuman...', style: TextStyle(color: Warna.kapurRedup)),
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Pengumuman belum bisa dimuat.', style: Gaya.isi),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.read(pengumumanProvider.notifier).segarkan(),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      ),
      data: (data) {
        if (data.items.isEmpty) {
          return Center(
            child: Text('Tidak ada pengumuman.', style: Gaya.isi.copyWith(color: Warna.kapurRedup)),
          );
        }

        return RefreshIndicator(
          color: Warna.kunyit,
          backgroundColor: Warna.tintaAngkat,
          onRefresh: () => ref.read(pengumumanProvider.notifier).segarkan(),
          child: ListView.separated(
            itemCount: data.items.length + (data.sedangMemuatLanjutan ? 1 : 0),
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index >= data.items.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: Text('Memuat lanjutan...', style: TextStyle(color: Warna.kapurRedup))),
                );
              }

              // Pemicu pagination saat baris ke-3 dari bawah terlihat (Section 8.1)
              if (index >= data.items.length - 3) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref.read(pengumumanProvider.notifier).muatLanjutan();
                });
              }

              final item = data.items[index];
              final duaBaris = _ambilDuaBaris(item.deskripsi);

              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => PengumumanDetailLayar(pengumuman: item),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.judul, style: Gaya.namaBaris, maxLines: 3, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(FormatTanggal.tanggal(item.dibuatPada), style: Gaya.label),
                      const SizedBox(height: 4),
                      Text(
                        duaBaris,
                        style: Gaya.catatan,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _DaftarPublikasi extends ConsumerWidget {
  const _DaftarPublikasi();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(publikasiProvider);

    return stateAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Memuat publikasi...', style: TextStyle(color: Warna.kapurRedup)),
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Publikasi belum bisa dimuat.', style: Gaya.isi),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.read(publikasiProvider.notifier).segarkan(),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      ),
      data: (data) {
        if (data.items.isEmpty) {
          return Center(
            child: Text('Tidak ada publikasi.', style: Gaya.isi.copyWith(color: Warna.kapurRedup)),
          );
        }

        return RefreshIndicator(
          color: Warna.kunyit,
          backgroundColor: Warna.tintaAngkat,
          onRefresh: () => ref.read(publikasiProvider.notifier).segarkan(),
          child: ListView.separated(
            itemCount: data.items.length + (data.sedangMemuatLanjutan ? 1 : 0),
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index >= data.items.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: Text('Memuat lanjutan...', style: TextStyle(color: Warna.kapurRedup))),
                );
              }

              if (index >= data.items.length - 3) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref.read(publikasiProvider.notifier).muatLanjutan();
                });
              }

              final item = data.items[index];

              // URL Sampul publikasi
              String? thumbUrl = item.thumbnail;
              if (thumbUrl != null && !thumbUrl.startsWith('http')) {
                thumbUrl = 'https://pddikti.kemdiktisaintek.go.id$thumbUrl';
              }

              return InkWell(
                onTap: () {
                  if (item.tautan != null && item.tautan!.isNotEmpty) {
                    konfirmasiDanBukaTautan(context, item.tautan!);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sampul rasio 3:4 lebar 72dp (tinggi 96dp)
                      Container(
                        width: 72,
                        height: 96,
                        color: Warna.tintaAngkat,
                        child: thumbUrl != null
                            ? CachedNetworkImage(
                                imageUrl: thumbUrl,
                                fit: BoxFit.cover,
                                fadeInDuration: Duration.zero,
                                fadeOutDuration: Duration.zero,
                                placeholder: (context, url) => Container(
                                  color: Warna.tintaAngkat,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.description_outlined, color: Warna.kapurRedup),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Warna.tintaAngkat,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.description_outlined, color: Warna.kapurRedup),
                                ),
                              )
                            : Container(
                                alignment: Alignment.center,
                                child: const Icon(Icons.description_outlined, color: Warna.kapurRedup),
                              ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.judul,
                              style: Gaya.namaBaris,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              FormatTanggal.tanggal(item.dibuatPada),
                              style: Gaya.label,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
