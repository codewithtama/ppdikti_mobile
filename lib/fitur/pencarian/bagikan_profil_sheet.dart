import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/tokens.dart';
import '../../core/util/profil_pdf_generator.dart';
import '../../data/model/pencarian_global.dart';

class BagikanProfilSheet extends StatefulWidget {
  const BagikanProfilSheet({
    super.key,
    this.mahasiswa,
    this.dosen,
  }) : assert(mahasiswa != null || dosen != null, 'Mahasiswa atau Dosen harus disediakan');

  final DetailMahasiswa? mahasiswa;
  final DetailDosen? dosen;

  static void tampilkan(
    BuildContext context, {
    DetailMahasiswa? mahasiswa,
    DetailDosen? dosen,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Warna.tinta,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BagikanProfilSheet(
        mahasiswa: mahasiswa,
        dosen: dosen,
      ),
    );
  }

  @override
  State<BagikanProfilSheet> createState() => _BagikanProfilSheetState();
}

class _BagikanProfilSheetState extends State<BagikanProfilSheet> {
  bool _sedangGeneratePdf = false;

  String _susunTeksMahasiswa(DetailMahasiswa m) {
    final r = m.ringkasan;
    final status = (m.statusTerakhir ?? r.status ?? 'Aktif').toUpperCase();
    final buffer = StringBuffer()
      ..writeln('🎓 *DATA MAHASISWA RESMI — PDDIKTI*')
      ..writeln('━━━━━━━━━━━━━━━━━━━━━━━━━')
      ..writeln('👤 *Nama*: ${r.nama}')
      ..writeln('🆔 *NIM*: ${r.nim}')
      ..writeln('🏛️ *Perguruan Tinggi*: ${r.namaPt}')
      ..writeln('📚 *Program Studi*: ${r.namaProdi} (${r.jenjang})')
      ..writeln('⚡ *Status*: $status')
      ..writeln('🗓️ *Tahun Masuk*: ${m.tanggalMasuk ?? (r.tahunMasuk ?? "-")}')
      ..writeln('━━━━━━━━━━━━━━━━━━━━━━━━━')
      ..writeln('🔍 Diverifikasi melalui Pangkalan Data Pendidikan Tinggi (PDDikti) Kemdiktisaintek RI.')
      ..writeln('Tautan resmi: https://pddikti.kemdiktisaintek.go.id');
    return buffer.toString();
  }

  String _susunTeksDosen(DetailDosen d) {
    final r = d.ringkasan;
    final status = (r.status ?? 'Aktif').toUpperCase();
    final buffer = StringBuffer()
      ..writeln('👨‍🏫 *DATA DOSEN RESMI — PDDIKTI*')
      ..writeln('━━━━━━━━━━━━━━━━━━━━━━━━━')
      ..writeln('👤 *Nama*: ${r.nama}')
      ..writeln('🆔 *NIDN*: ${r.nidn}')
      ..writeln('🏛️ *Homebase PT*: ${r.namaPt}')
      ..writeln('📚 *Homebase Prodi*: ${r.namaProdi}')
      ..writeln('⚡ *Status Aktivitas*: $status')
      ..writeln('🎖️ *Jabatan*: ${r.jabatanAkademik ?? "-"}')
      ..writeln('🎓 *Pendidikan*: ${r.pendidikanTertinggi ?? "-"}')
      ..writeln('━━━━━━━━━━━━━━━━━━━━━━━━━')
      ..writeln('🔍 Diverifikasi melalui Pangkalan Data Pendidikan Tinggi (PDDikti) Kemdiktisaintek RI.')
      ..writeln('Tautan resmi: https://pddikti.kemdiktisaintek.go.id');
    return buffer.toString();
  }

  Future<void> _bagikanTeks() async {
    Navigator.of(context).pop();
    final teks = widget.mahasiswa != null
        ? _susunTeksMahasiswa(widget.mahasiswa!)
        : _susunTeksDosen(widget.dosen!);

    await SharePlus.instance.share(
      ShareParams(
        text: teks,
        subject: widget.mahasiswa != null
            ? 'Data Mahasiswa - ${widget.mahasiswa!.ringkasan.nama}'
            : 'Data Dosen - ${widget.dosen!.ringkasan.nama}',
      ),
    );
  }

  Future<void> _bagikanPdf({bool bukaLangsung = false}) async {
    if (_sedangGeneratePdf) return;
    setState(() => _sedangGeneratePdf = true);

    try {
      final berkas = widget.mahasiswa != null
          ? await ProfilPdfGenerator.buatPdfMahasiswa(detail: widget.mahasiswa!)
          : await ProfilPdfGenerator.buatPdfDosen(detail: widget.dosen!);

      if (!mounted) return;
      Navigator.of(context).pop();

      if (bukaLangsung) {
        await OpenFilex.open(berkas.path);
      } else {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(berkas.path)],
            text: widget.mahasiswa != null
                ? 'Lembar Data Resmi Mahasiswa: ${widget.mahasiswa!.ringkasan.nama}'
                : 'Lembar Data Resmi Dosen: ${widget.dosen!.ringkasan.nama}',
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _sedangGeneratePdf = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat dokumen PDF: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final judul = widget.mahasiswa != null
        ? 'Bagikan Profil Mahasiswa'
        : 'Bagikan Profil Dosen';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  PhosphorIconsRegular.shareNetwork,
                  color: Warna.kunyit,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  judul,
                  style: const TextStyle(
                    color: Warna.kapur,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.x, color: Warna.kapurRedup, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(color: Warna.garis, height: 20),
            const SizedBox(height: 8),

            // Opsi 1: WhatsApp / Teks Ringkasan
            _ItemOpsiBagikan(
              icon: PhosphorIconsRegular.whatsappLogo,
              iconColor: const Color(0xFF22C55E),
              judul: 'Kirim Ringkasan Teks ke WhatsApp',
              deskripsi: 'Format teks rapi dengan identitas, NIM/NIDN, dan status keaktifan.',
              onTap: _bagikanTeks,
            ),
            const SizedBox(height: 12),

            // Opsi 2: Bagikan File PDF Resmi
            _ItemOpsiBagikan(
              icon: PhosphorIconsRegular.filePdf,
              iconColor: const Color(0xFFEF4444),
              judul: 'Bagikan Dokumen PDF Resmi',
              deskripsi: 'Format surat resmi berkop Kemdiktisaintek PDDikti beserta riwayat semester.',
              isLoading: _sedangGeneratePdf,
              onTap: () => _bagikanPdf(bukaLangsung: false),
            ),
            const SizedBox(height: 12),

            // Opsi 3: Buka & Pratinjau PDF
            _ItemOpsiBagikan(
              icon: PhosphorIconsRegular.eye,
              iconColor: Warna.laut,
              judul: 'Buka & Pratinjau Dokumen PDF',
              deskripsi: 'Lihat langsung dokumen PDF di perangkat Anda untuk diperiksa atau dicetak.',
              onTap: () => _bagikanPdf(bukaLangsung: true),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _ItemOpsiBagikan extends StatelessWidget {
  const _ItemOpsiBagikan({
    required this.icon,
    required this.iconColor,
    required this.judul,
    required this.deskripsi,
    required this.onTap,
    this.isLoading = false,
  });

  final IconData icon;
  final Color iconColor;
  final String judul;
  final String deskripsi;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Warna.tintaAngkat,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Warna.garis, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: iconColor,
                      ),
                    )
                  : Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    judul,
                    style: const TextStyle(
                      color: Warna.kapur,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    deskripsi,
                    style: const TextStyle(
                      color: Warna.kapurRedup,
                      fontSize: 11.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              PhosphorIconsRegular.caretRight,
              color: Warna.kapurRedup,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

