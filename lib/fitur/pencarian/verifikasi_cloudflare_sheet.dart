import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/net/sesi_cloudflare.dart';
import '../../core/theme/tokens.dart';

class VerifikasiCloudflareSheet extends ConsumerStatefulWidget {
  const VerifikasiCloudflareSheet({
    super.key,
    this.urlUji = 'https://pddikti.kemdiktisaintek.go.id/',
  });

  final String urlUji;

  static Future<bool?> tampilkan(BuildContext context, {String? url}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VerifikasiCloudflareSheet(
        urlUji: url ?? 'https://pddikti.kemdiktisaintek.go.id/',
      ),
    );
  }

  @override
  ConsumerState<VerifikasiCloudflareSheet> createState() => _VerifikasiCloudflareSheetState();
}

class _VerifikasiCloudflareSheetState extends ConsumerState<VerifikasiCloudflareSheet> {
  late final WebViewController _controller;
  bool _sedangMemuat = true;
  String _statusPesan = 'Menghubungkan ke PDDikti...';
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _inisialisasiWebView();
  }

  void _inisialisasiWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Warna.tinta)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) {
              setState(() {
                _sedangMemuat = true;
                _statusPesan = 'Memuat halaman verifikasi PDDikti...';
              });
            }
          },
          onPageFinished: (url) async {
            if (mounted) {
              setState(() {
                _sedangMemuat = false;
                _statusPesan = 'Silakan centang verifikasi di bawah jika muncul';
              });
            }
            await _periksaDanAmbilCookie();
          },
          onWebResourceError: (error) {
            if (mounted) {
              setState(() {
                _statusPesan = 'Gagal memuat: ${error.description}';
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.urlUji));

    // Polling setiap 1,5 detik untuk mengecek apakah cf_clearance sudah didapat
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _periksaDanAmbilCookie();
    });
  }

  Future<void> _periksaDanAmbilCookie() async {
    try {
      final cookieObj = await _controller.runJavaScriptReturningResult('document.cookie');
      final cookieStr = cookieObj.toString().replaceAll('"', '').trim();

      final uaObj = await _controller.runJavaScriptReturningResult('navigator.userAgent');
      final uaStr = uaObj.toString().replaceAll('"', '').trim();

      final titleObj = await _controller.runJavaScriptReturningResult('document.title');
      final titleStr = titleObj.toString().replaceAll('"', '').trim();

      // Jika cf_clearance atau cookie pddikti sudah ada, atau judul bukan lagi verifikasi
      if (cookieStr.contains('cf_clearance') ||
          (cookieStr.isNotEmpty && !titleStr.toLowerCase().contains('verifikasi'))) {
        _pollingTimer?.cancel();

        ref.read(sesiCloudflareProvider.notifier).simpanSesi(
              cookies: cookieStr,
              userAgent: uaStr.isNotEmpty
                  ? uaStr
                  : 'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36',
            );

        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verifikasi berhasil! Sesi aktif tersimpan.'),
              backgroundColor: Warna.laut,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Warna.tinta,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        border: Border(
          top: BorderSide(color: Warna.garisTegas, width: 1),
          left: BorderSide(color: Warna.garis, width: 1),
          right: BorderSide(color: Warna.garis, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header Sheet
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Warna.tintaAngkat,
              border: Border(bottom: BorderSide(color: Warna.garis, width: 1)),
            ),
            child: Row(
              children: [
                const Icon(PhosphorIconsRegular.shieldCheck, size: 20, color: Warna.kunyit),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verifikasi Keamanan PDDikti',
                        style: TextStyle(
                          color: Warna.kapur,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Selesaikan verifikasi bot resmi Cloudflare 1x untuk membuka pencarian langsung.',
                        style: TextStyle(color: Warna.kapurRedup, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.x, size: 18, color: Warna.kapurRedup),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),

          // Status & Indikator
          if (_sedangMemuat)
            const LinearProgressIndicator(
              backgroundColor: Warna.tintaAngkat,
              color: Warna.kunyit,
              minHeight: 2,
            ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: Warna.tinta,
            child: Text(
              _statusPesan,
              style: const TextStyle(color: Warna.kapurRedup, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),

          const Divider(height: 1, color: Warna.garis),

          // WebView Container
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),

          // Footer info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Warna.tintaAngkat,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => _controller.reload(),
                  icon: const Icon(PhosphorIconsRegular.arrowsClockwise, size: 16, color: Warna.kunyit),
                  label: const Text('Muat Ulang Halaman', style: TextStyle(color: Warna.kunyit, fontSize: 12)),
                ),
                ElevatedButton(
                  onPressed: () => _periksaDanAmbilCookie(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Warna.kunyit,
                    foregroundColor: Warna.tinta,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: const Text('Cek Selesai', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

