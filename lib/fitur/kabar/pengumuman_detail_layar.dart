import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import '../../core/format/tanggal.dart';
import '../../core/html/html_bersih.dart';
import '../../core/theme/tokens.dart';
import '../../data/model/pengumuman.dart';
import 'tautan_keluar_sheet.dart';

class PengumumanDetailLayar extends StatelessWidget {
  const PengumumanDetailLayar({
    super.key,
    required this.pengumuman,
  });

  final Pengumuman pengumuman;

  @override
  Widget build(BuildContext context) {
    final htmlBersih = bersihkanHtml(pengumuman.deskripsi);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengumuman'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              Text(pengumuman.judul, style: Gaya.namaDetail),
              const SizedBox(height: 6),
              Text(
                FormatTanggal.tanggal(pengumuman.dibuatPada),
                style: Gaya.label,
              ),
              const SizedBox(height: 16),

              if (pengumuman.tautan != null && pengumuman.tautan!.isNotEmpty) ...[
                OutlinedButton.icon(
                  onPressed: () => konfirmasiDanBukaTautan(context, pengumuman.tautan!),
                  icon: const Icon(Icons.attachment, size: 18),
                  label: const Text('Buka lampiran'),
                ),
                const SizedBox(height: 20),
              ],

              const Divider(height: 1),
              const SizedBox(height: 20),

              HtmlWidget(
                htmlBersih,
                textStyle: Gaya.bacaan,
                onTapUrl: (url) {
                  konfirmasiDanBukaTautan(context, url);
                  return true;
                },
                customStylesBuilder: (element) {
                  return {
                    'text-align': 'left',
                    'color': '#ECE7DA',
                  };
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

