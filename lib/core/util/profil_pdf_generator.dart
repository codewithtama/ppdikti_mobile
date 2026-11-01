import 'dart:io';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../data/model/pencarian_global.dart';

class ProfilPdfGenerator {
  const ProfilPdfGenerator._();

  static String _formatWaktuSekarang() {
    try {
      initializeDateFormatting('id_ID', null);
      return DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(DateTime.now());
    } catch (_) {
      return DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now());
    }
  }

  /// Membuat dokumen PDF resmi untuk data profil mahasiswa
  static Future<File> buatPdfMahasiswa({
    required DetailMahasiswa detail,
    Directory? direktoriTarget,
  }) async {
    final pdf = pw.Document(
      title: 'Data Mahasiswa - ${detail.ringkasan.nama}',
      author: 'PDDikti Kemdiktisaintek RI',
    );

    final mhs = detail.ringkasan;
    final tanggalCetak = _formatWaktuSekarang();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Kop Dokumen Resmi PDDikti
              _bangunKopDokumen(),
              pw.SizedBox(height: 14),

              // Garis pemisah kop ganda
              pw.Container(
                height: 2,
                color: PdfColors.blue900,
              ),
              pw.SizedBox(height: 2),
              pw.Container(
                height: 0.8,
                color: PdfColors.blue900,
              ),
              pw.SizedBox(height: 16),

              // Judul Dokumen
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'LEMBAR INFORMASI STATUS MAHASISWA',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Rujukan Resmi Pangkalan Data Pendidikan Tinggi (PDDikti)',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Tabel Identitas Mahasiswa
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                  color: PdfColors.grey50,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _barisData('Nama Mahasiswa', mhs.nama, tebal: true),
                    _barisData('Nomor Induk Mahasiswa (NIM)', mhs.nim, tebal: true),
                    _barisData('Perguruan Tinggi', mhs.namaPt),
                    _barisData('Program Studi', mhs.namaProdi),
                    _barisData('Jenjang Pendidikan', mhs.jenjang),
                    _barisData('Jenis Kelamin', detail.jenisKelamin ?? '-'),
                    _barisData('Status Mahasiswa Saat Ini', (detail.statusTerakhir ?? mhs.status ?? 'Aktif').toUpperCase(), tebal: true, warnaTeks: (detail.statusTerakhir ?? mhs.status ?? '').toLowerCase().contains('aktif') ? PdfColors.green800 : PdfColors.amber800),
                    _barisData('Tahun / Tanggal Masuk', detail.tanggalMasuk ?? (mhs.tahunMasuk ?? '-')),
                    _barisData('Status Pendaftaran', detail.statusAwal),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Riwayat Status Semester (jika ada)
              if (detail.riwayatKuliah.isNotEmpty) ...[
                pw.Text(
                  'RIWAYAT STATUS KULIAH PER SEMESTER',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.TableHelper.fromTextArray(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
                  cellStyle: const pw.TextStyle(fontSize: 8),
                  cellHeight: 20,
                  cellAlignment: pw.Alignment.centerLeft,
                  headers: const <String>['No', 'Semester', 'Status', 'SKS Diambil'],
                  data: List<List<String>>.generate(
                    detail.riwayatKuliah.length,
                    (index) {
                      final item = detail.riwayatKuliah[index];
                      return <String>[
                        '${index + 1}',
                        item.semester,
                        item.status,
                        '${item.sks} SKS',
                      ];
                    },
                  ),
                ),
                pw.SizedBox(height: 16),
              ],

              pw.Spacer(),

              // Catatan Kaki & Tanda Pengesahan Sistem
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Keterangan Keabsahan Dokumen:',
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Dokumen ini dicetak otomatis dari aplikasi PDDikti Mobile berdasarkan data terdaftar pada basis data resmi Kementerian Pendidikan Tinggi, Sains, dan Teknologi RI. Tidak memerlukan tanda tangan basah.',
                            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 16),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Waktu Cetak:',
                          style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                        ),
                        pw.Text(
                          tanggalCetak,
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final dir = direktoriTarget ?? await getTemporaryDirectory();
    final sanitasiNim = mhs.nim.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final berkas = File('${dir.path}/PDDikti_Mhs_${sanitasiNim}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await berkas.writeAsBytes(await pdf.save());
    return berkas;
  }

  /// Membuat dokumen PDF resmi untuk data profil dosen
  static Future<File> buatPdfDosen({
    required DetailDosen detail,
    Directory? direktoriTarget,
  }) async {
    final pdf = pw.Document(
      title: 'Data Dosen - ${detail.ringkasan.nama}',
      author: 'PDDikti Kemdiktisaintek RI',
    );

    final dsn = detail.ringkasan;
    final tanggalCetak = _formatWaktuSekarang();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _bangunKopDokumen(),
              pw.SizedBox(height: 14),

              pw.Container(height: 2, color: PdfColors.blue900),
              pw.SizedBox(height: 2),
              pw.Container(height: 0.8, color: PdfColors.blue900),
              pw.SizedBox(height: 16),

              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'LEMBAR INFORMASI PROFIL DOSEN',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Rujukan Resmi Pangkalan Data Pendidikan Tinggi (PDDikti)',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Tabel Identitas Dosen
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                  color: PdfColors.grey50,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _barisData('Nama Dosen', dsn.nama, tebal: true),
                    _barisData('NIDN / NUPTK', dsn.nidn, tebal: true),
                    _barisData('Perguruan Tinggi Homebase', dsn.namaPt),
                    _barisData('Program Studi Homebase', dsn.namaProdi),
                    _barisData('Status Ikatan Kerja', detail.statusIkatanKerja),
                    _barisData('Status Keaktifan', (dsn.status ?? 'Aktif').toUpperCase(), tebal: true, warnaTeks: (dsn.status ?? '').toLowerCase().contains('aktif') ? PdfColors.green800 : PdfColors.amber800),
                    _barisData('Jabatan Fungsional / Akademik', dsn.jabatanAkademik ?? '-'),
                    _barisData('Pendidikan Tertinggi', dsn.pendidikanTertinggi ?? '-'),
                    _barisData('Jenis Kelamin', detail.jenisKelamin ?? '-'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Riwayat Pendidikan Dosen (jika ada)
              if (detail.riwayatPendidikan.isNotEmpty) ...[
                pw.Text(
                  'RIWAYAT PENDIDIKAN TINGGI',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.TableHelper.fromTextArray(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
                  cellStyle: const pw.TextStyle(fontSize: 8),
                  cellHeight: 20,
                  cellAlignment: pw.Alignment.centerLeft,
                  headers: const <String>['Jenjang', 'Perguruan Tinggi', 'Bidang Studi', 'Tahun Lulus'],
                  data: List<List<String>>.generate(
                    detail.riwayatPendidikan.length,
                    (index) {
                      final item = detail.riwayatPendidikan[index];
                      return <String>[
                        item.jenjang,
                        item.perguruanTinggi,
                        item.bidangStudi,
                        item.tahunLulus,
                      ];
                    },
                  ),
                ),
                pw.SizedBox(height: 16),
              ],

              pw.Spacer(),

              // Keterangan Keabsahan
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Keterangan Keabsahan Dokumen:',
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Dokumen ini dicetak otomatis dari aplikasi PDDikti Mobile berdasarkan data terdaftar pada basis data resmi Kementerian Pendidikan Tinggi, Sains, dan Teknologi RI.',
                            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 16),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Waktu Cetak:',
                          style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                        ),
                        pw.Text(
                          tanggalCetak,
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final dir = direktoriTarget ?? await getTemporaryDirectory();
    final sanitasiNidn = dsn.nidn.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final berkas = File('${dir.path}/PDDikti_Dosen_${sanitasiNidn}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await berkas.writeAsBytes(await pdf.save());
    return berkas;
  }

  static pw.Widget _bangunKopDokumen() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Monogram lambang resmi
        pw.Container(
          width: 44,
          height: 44,
          decoration: const pw.BoxDecoration(
            color: PdfColors.blue900,
            shape: pw.BoxShape.circle,
          ),
          child: pw.Center(
            child: pw.Text(
              'DIKTI',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        pw.SizedBox(width: 14),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'KEMENTERIAN PENDIDIKAN TINGGI, SAINS, DAN TEKNOLOGI',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              pw.Text(
                'DIREKTORAT JENDERAL PENDIDIKAN TINGGI',
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
              pw.Text(
                'Pangkalan Data Pendidikan Tinggi (PDDikti) - https://pddikti.kemdiktisaintek.go.id',
                style: const pw.TextStyle(
                  fontSize: 7.5,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _barisData(String label, String nilai, {bool tebal = false, PdfColor? warnaTeks}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 170,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
            ),
          ),
          pw.Text(': ', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800)),
          pw.Expanded(
            child: pw.Text(
              nilai.isEmpty ? '-' : nilai,
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: tebal ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: warnaTeks ?? PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

