import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Pembantu pemformatan dan pemetaan warna status akademik mahasiswa dan dosen.
abstract final class StatusAkademikHelper {
  /// Mengambil label ringkas untuk badge (misal: "NON-AKTIF", "LULUS", "AKTIF", "CUTI")
  static String ringkasStatus(String? statusRaw) {
    if (statusRaw == null || statusRaw.trim().isEmpty) return '';
    final s = statusRaw.trim();
    final lower = s.toLowerCase();

    // 1. Inaktif / Tidak Aktif / Non-Aktif
    if (lower.startsWith('non-aktif') ||
        lower.startsWith('non aktif') ||
        lower.startsWith('tidak aktif') ||
        lower == 'non-aktif' ||
        lower == 'tidak aktif' ||
        lower.contains('non-aktif') ||
        lower.contains('tidak aktif')) {
      return 'NON-AKTIF';
    }

    // 2. Lulus / Alumni
    if (lower.startsWith('lulus') || lower.contains('lulus')) {
      return 'LULUS';
    }

    // 3. Cuti
    if (lower.startsWith('cuti') || lower.contains('cuti')) {
      return 'CUTI';
    }

    // 4. Keluar / Mengundurkan diri
    if (lower.contains('keluar') || lower.contains('mengundurkan')) {
      return 'KELUAR';
    }

    // 5. Drop Out / Dikeluarkan
    if (lower.contains('drop out') || lower.contains('dikeluarkan') || lower.contains('do')) {
      return 'DROP OUT';
    }

    // 6. Mutasi / Pindah
    if (lower.contains('mutasi') || lower.contains('pindah')) {
      return 'MUTASI';
    }

    // 7. Wafat / Meninggal
    if (lower.contains('wafat') || lower.contains('meninggal')) {
      return 'WAFAT';
    }

    // 8. Tugas Belajar
    if (lower.contains('tugas belajar')) {
      return 'TUGAS BELAJAR';
    }

    // 9. Pensiun
    if (lower.contains('pensiun')) {
      return 'PENSIUN';
    }

    // 10. Aktif (pastikan bukan non-aktif / tidak aktif)
    if (lower.startsWith('aktif') || lower.contains('aktif')) {
      return 'AKTIF';
    }

    // Fallback: potong semester di belakang tanda '-' jika ada
    if (s.contains('-')) {
      final parts = s.split('-');
      if (parts.length >= 2 &&
          (parts[0].trim().toLowerCase() == 'non' || parts[0].trim().toLowerCase() == 'tidak')) {
        return '${parts[0].trim()}-${parts[1].trim()}'.toUpperCase();
      }
      return parts[0].trim().toUpperCase();
    }

    return s.toUpperCase();
  }

  /// Menentukan warna identitas status (Kunyit: Lulus, Karang: Inaktif/Keluar, Laut: Aktif)
  static Color warnaTeks(String? statusRaw) {
    if (statusRaw == null || statusRaw.trim().isEmpty) return Warna.kapurRedup;
    final lower = statusRaw.toLowerCase();

    // Inaktif / Red alert
    if (lower.contains('non') ||
        lower.contains('tidak') ||
        lower.contains('keluar') ||
        lower.contains('mengundurkan') ||
        lower.contains('drop out') ||
        lower.contains('dikeluarkan') ||
        lower.contains('wafat') ||
        lower.contains('pensiun')) {
      return Warna.karang; // Coral red
    }

    // Lulus / Achievement / Alumni
    if (lower.contains('lulus')) {
      return Warna.kunyit; // Kunyit gold
    }

    // Cuti / Netral
    if (lower.contains('cuti') || lower.contains('mutasi') || lower.contains('tugas belajar')) {
      return Warna.kapurRedup;
    }

    // Aktif
    if (lower.contains('aktif')) {
      return Warna.laut; // Laut mint
    }

    return Warna.kapurRedup;
  }

  /// Warna latar transparan untuk badge
  static Color warnaLatar(String? statusRaw) {
    return warnaTeks(statusRaw).withValues(alpha: 0.15);
  }
}

