import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/format/status_akademik.dart';
import '../../core/theme/tokens.dart';
import '../../data/model/pencarian_global.dart';

enum TipeKartuDigital { mahasiswa, dosen }

class KartuDigitalWidget extends StatelessWidget {
  const KartuDigitalWidget({
    super.key,
    this.mahasiswa,
    this.dosen,
    this.tampilkanSisiBelakang = false,
  }) : assert(mahasiswa != null || dosen != null, 'Mahasiswa atau Dosen wajib ada');

  final DetailMahasiswa? mahasiswa;
  final DetailDosen? dosen;
  final bool tampilkanSisiBelakang;

  TipeKartuDigital get tipe =>
      mahasiswa != null ? TipeKartuDigital.mahasiswa : TipeKartuDigital.dosen;

  String get nama => mahasiswa?.ringkasan.nama ?? dosen?.ringkasan.nama ?? '';
  String get nomorInduk =>
      mahasiswa?.ringkasan.nim ?? (dosen?.ringkasan.nidn.isNotEmpty == true ? dosen!.ringkasan.nidn : '-');
  String get labelNomorInduk =>
      tipe == TipeKartuDigital.mahasiswa ? 'NIM' : 'NIDN / NUP';
  String get perguruanTinggi =>
      mahasiswa?.ringkasan.namaPt ?? dosen?.ringkasan.namaPt ?? '';
  String get prodi =>
      mahasiswa?.ringkasan.namaProdi ?? dosen?.ringkasan.namaProdi ?? '';
  String get jenjang => mahasiswa?.ringkasan.jenjang ?? '';
  String get status => mahasiswa?.ringkasan.status ?? dosen?.ringkasan.status ?? 'Aktif';

  String get qrDataUrl {
    if (mahasiswa != null) {
      final idEnc = Uri.encodeComponent(mahasiswa!.ringkasan.id);
      return 'https://pddikti.kemdiktisaintek.go.id/detail-mahasiswa/$idEnc';
    } else {
      final idEnc = Uri.encodeComponent(dosen!.ringkasan.id);
      return 'https://pddikti.kemdiktisaintek.go.id/detail-dosen/$idEnc';
    }
  }

  String _hitungInisial(String str) {
    final kata = str.trim().split(RegExp(r'\s+')).where((k) => k.isNotEmpty).toList();
    if (kata.isEmpty) return 'K';
    if (kata.length == 1) return kata[0][0].toUpperCase();
    return '${kata[0][0]}${kata[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = StatusAkademikHelper.warnaTeks(status);

    return Container(
      width: 350,
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF131722),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Warna.kunyit.withValues(alpha: 0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E2332),
            Color(0xFF11141E),
            Color(0xFF0B0D13),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // Watermark Pola Lambang Keamanan di Latar Belakang
            const Positioned(
              right: -25,
              bottom: -25,
              child: Opacity(
                opacity: 0.05,
                child: Icon(
                  PhosphorIconsFill.shieldCheck,
                  size: 210,
                  color: Warna.kunyit,
                ),
              ),
            ),

            if (tampilkanSisiBelakang)
              _buildSisiBelakang()
            else
              _buildSisiDepan(statusColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSisiDepan(Color statusColor) {
    final inisial = _hitungInisial(nama);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header Kartu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'KEMDIKTISAINTEK REPUBLIK INDONESIA',
                      style: TextStyle(
                        color: Warna.kunyit,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      'Pangkalan Data Pendidikan Tinggi (PDDikti)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Warna.kunyit.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        tipe == TipeKartuDigital.mahasiswa
                            ? 'KARTU IDENTITAS MAHASISWA DIGITAL'
                            : 'KARTU IDENTITAS DOSEN DIGITAL',
                        style: const TextStyle(
                          color: Warna.kunyit,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: QrImageView(
                  data: qrDataUrl,
                  version: QrVersions.auto,
                  size: 34,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),

          // Baris Identitas Utama (Avatar Monogram + Nama & Nomor)
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E2638),
                  border: Border.all(color: Warna.kunyit, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  inisial,
                  style: const TextStyle(
                    color: Warna.kunyit,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$labelNomorInduk: $nomorInduk',
                      style: const TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Footer Kartu: Kampus, Prodi & Status Badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          perguruanTinggi,
                          style: const TextStyle(
                            color: Warna.kunyit,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          jenjang.isNotEmpty ? '$jenjang - $prodi' : prodi,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: statusColor, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Row(
                children: [
                  Icon(PhosphorIconsFill.shieldCheck, size: 10, color: Warna.laut),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'TERVERIFIKASI PANGKALAN DATA PENDIDIKAN TINGGI',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSisiBelakang() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // QR Code Besar
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Warna.kunyit, width: 1.5),
            ),
            child: QrImageView(
              data: qrDataUrl,
              version: QrVersions.auto,
              size: 110,
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 14),

          // Teks Penjelasan & Validasi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'VALIDASI DOKUMEN DIGITAL',
                  style: TextStyle(
                    color: Warna.kunyit,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pindai kode QR menggunakan kamera ponsel untuk memverifikasi keabsahan profil dan riwayat studi langsung pada server resmi PDDikti Kemdiktisaintek RI.',
                  style: TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 8.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ID: ${mahasiswa?.ringkasan.id ?? dosen?.ringkasan.id ?? "-"}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 7.5,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                const Text(
                  'KEMENTERIAN PENDIDIKAN TINGGI, SAINS, DAN TEKNOLOGI',
                  style: TextStyle(
                    color: Warna.kapurRedup,
                    fontSize: 6.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
