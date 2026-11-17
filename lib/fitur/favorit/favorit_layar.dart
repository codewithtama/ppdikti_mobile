import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/tokens.dart';
import '../../data/model/pencarian_global.dart';
import '../../data/sumber/db_lokal.dart';
import 'favorit_vm.dart';

class FavoritLayar extends ConsumerStatefulWidget {
  const FavoritLayar({super.key});

  @override
  ConsumerState<FavoritLayar> createState() => _FavoritLayarState();
}

class _FavoritLayarState extends ConsumerState<FavoritLayar> {
  TipeFavorit? _filterTipe;

  IconData _ikonTipe(TipeFavorit tipe) {
    switch (tipe) {
      case TipeFavorit.kampus:
        return PhosphorIconsRegular.buildings;
      case TipeFavorit.prodi:
        return PhosphorIconsRegular.graduationCap;
      case TipeFavorit.mahasiswa:
        return PhosphorIconsRegular.student;
      case TipeFavorit.dosen:
        return PhosphorIconsRegular.chalkboardTeacher;
    }
  }

  void _bukaDetail(ItemFavorit item) {
    final encId = Uri.encodeComponent(item.id);
    switch (item.tipe) {
      case TipeFavorit.kampus:
        context.push('/kampus/$encId');
      case TipeFavorit.prodi:
        final prodi = HasilProdi.fromJson(item.metaJson);
        context.push('/prodi/$encId', extra: prodi);
      case TipeFavorit.mahasiswa:
        final mhs = HasilMahasiswa.fromJson(item.metaJson);
        context.push('/mahasiswa/$encId', extra: mhs);
      case TipeFavorit.dosen:
        final dsn = HasilDosen.fromJson(item.metaJson);
        context.push('/dosen/$encId', extra: dsn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final semuaFavorit = ref.watch(favoritProvider);
    final daftar = _filterTipe == null
        ? semuaFavorit
        : semuaFavorit.where((e) => e.tipe == _filterTipe).toList();

    return Scaffold(
      backgroundColor: Warna.tinta,
      appBar: AppBar(
        title: const Text('Tersimpan & Favorit'),
        backgroundColor: Warna.tinta,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                _FilterChipFavorit(
                  label: 'Semua (${semuaFavorit.length})',
                  aktif: _filterTipe == null,
                  onTap: () => setState(() => _filterTipe = null),
                ),
                ...TipeFavorit.values.map((t) {
                  final jumlah =
                      semuaFavorit.where((e) => e.tipe == t).length;
                  return _FilterChipFavorit(
                    label: '${t.label} ($jumlah)',
                    aktif: _filterTipe == t,
                    onTap: () => setState(() => _filterTipe = t),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1, color: Warna.garis),
          Expanded(
            child: daftar.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Warna.tintaAngkat,
                              shape: BoxShape.circle,
                              border: Border.all(color: Warna.garis),
                            ),
                            child: const Icon(
                              PhosphorIconsRegular.bookmarkSimple,
                              size: 40,
                              color: Warna.kunyit,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Belum Ada Item Tersimpan',
                            style: TextStyle(
                              color: Warna.kapur,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Ketuk ikon Bookmark pada detail Kampus, Prodi, Mahasiswa, atau Dosen untuk menyimpannya secara luring.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Warna.kapurRedup,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: daftar.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: Warna.garis),
                    itemBuilder: (context, index) {
                      final item = daftar[index];
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Warna.tintaAngkat,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Warna.garis),
                          ),
                          child: Icon(
                            _ikonTipe(item.tipe),
                            color: Warna.kunyit,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          item.judul,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Warna.kapur,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${item.tipe.label} • ${item.subjudul}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Warna.kapurRedup,
                            fontSize: 12,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            PhosphorIconsFill.bookmarkSimple,
                            color: Warna.kunyit,
                            size: 20,
                          ),
                          tooltip: 'Hapus dari Tersimpan',
                          onPressed: () {
                            ref
                                .read(favoritProvider.notifier)
                                .hapus(item.id, item.tipe);
                          },
                        ),
                        onTap: () => _bukaDetail(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipFavorit extends StatelessWidget {
  const _FilterChipFavorit({
    required this.label,
    required this.aktif,
    required this.onTap,
  });

  final String label;
  final bool aktif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: aktif ? Warna.kunyit : Warna.tintaAngkat,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: aktif ? Warna.kunyit : Warna.garis,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: aktif ? Warna.tinta : Warna.kapur,
              fontSize: 12,
              fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
