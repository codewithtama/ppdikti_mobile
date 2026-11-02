import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/tokens.dart';
import '../kampus/logo_kampus.dart';
import 'komparasi_vm.dart';

class BarKomparasiMelayang extends ConsumerWidget {
  const BarKomparasiMelayang({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(komparasiProvider);
    final total = state.totalSemuaItem;

    if (total == 0) return const SizedBox.shrink();

    final jmlKampus = state.daftarKampus.length;
    final jmlProdi = state.daftarProdi.length;

    String ringkasanTeks;
    if (jmlKampus > 0 && jmlProdi > 0) {
      ringkasanTeks = '$jmlKampus Kampus & $jmlProdi Prodi dipilih';
    } else if (jmlKampus > 0) {
      ringkasanTeks = '$jmlKampus Kampus siap dibandingkan';
    } else {
      ringkasanTeks = '$jmlProdi Prodi siap dibandingkan';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Warna.tintaAngkat,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Warna.kunyit.withValues(alpha: 0.8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Tumpukan Avatar Logo Kampus Terpilih
          if (jmlKampus > 0) ...[
            SizedBox(
              width: (jmlKampus * 22.0) + 16.0,
              height: 34,
              child: Stack(
                children: List.generate(jmlKampus, (i) {
                  final k = state.daftarKampus[i];
                  return Positioned(
                    left: i * 20.0,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Warna.tinta, width: 2),
                      ),
                      child: LogoKampus(
                        idSp: k.idSp,
                        nama: k.nama,
                        ukuran: 30,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 8),
          ] else ...[
            const Icon(PhosphorIconsFill.scales, color: Warna.kunyit, size: 24),
            const SizedBox(width: 10),
          ],

          // Label Teks
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ringkasanTeks,
                  style: const TextStyle(
                    color: Warna.kapur,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Maks. 3 entri per kategori',
                  style: TextStyle(
                    color: Warna.kapurRedup.withValues(alpha: 0.9),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Tombol Bandingkan
          FilledButton(
            onPressed: () {
              context.push('/komparasi');
            },
            style: FilledButton.styleFrom(
              backgroundColor: Warna.kunyit,
              foregroundColor: Warna.tinta,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Bandingkan',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),

          const SizedBox(width: 4),

          // Tombol Reset / Tutup
          IconButton(
            icon: const Icon(PhosphorIconsRegular.x, size: 18, color: Warna.kapurRedup),
            tooltip: 'Hapus semua pilihan komparasi',
            visualDensity: VisualDensity.compact,
            onPressed: () {
              ref.read(komparasiProvider.notifier).bersihkanSemua();
            },
          ),
        ],
      ),
    );
  }
}

