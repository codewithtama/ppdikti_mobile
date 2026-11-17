import 'dart:async';
import 'dart:convert';
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
  ConsumerState<VerifikasiCloudflareSheet> createState() =>
      _VerifikasiCloudflareSheetState();
}

class _VerifikasiCloudflareSheetState
    extends ConsumerState<VerifikasiCloudflareSheet> {
  late final WebViewController _controller;
  bool _sedangMemuat = true;
  bool _sudahSelesai = false;
  String _statusPesan = 'Menghubungkan ke PDDikti...';
  Timer? _pollingTimer;

  static const String _uaMobile =
      'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36';

  static const String _jsHookVerifikasi = '''
(function() {
  if (window.__pddiktiHookInstalled) return;
  window.__pddiktiHookInstalled = true;

  function kirimToken(token) {
    if (!token || typeof token !== 'string' || !token.trim()) return;
    try {
      PddiktiVerifikasi.postMessage(JSON.stringify({
        recaptchaToken: token.trim(),
        cookies: document.cookie || '',
        userAgent: navigator.userAgent || ''
      }));
    } catch (_) {}
  }

  // Tangkap X-Recaptcha-Token dari fetch resmi jika ada
  var origFetch = window.fetch;
  if (origFetch) {
    window.fetch = function(input, init) {
      try {
        if (init && init.headers) {
          var h = init.headers;
          var t = (typeof h.get === 'function')
            ? (h.get('X-Recaptcha-Token') || h.get('x-recaptcha-token'))
            : (h['X-Recaptcha-Token'] || h['x-recaptcha-token']);
          if (t) kirimToken(t);
        }
      } catch (_) {}
      return origFetch.apply(this, arguments);
    };
  }

  // Tangkap X-Recaptcha-Token dari XMLHttpRequest resmi jika ada
  var origSetHeader = XMLHttpRequest.prototype.setRequestHeader;
  if (origSetHeader) {
    XMLHttpRequest.prototype.setRequestHeader = function(name, value) {
      try {
        if (name && name.toLowerCase() === 'x-recaptcha-token' && value) {
          kirimToken(value);
        }
      } catch (_) {}
      return origSetHeader.apply(this, arguments);
    };
  }
})();
''';

  @override
  void initState() {
    super.initState();
    _inisialisasiWebView();
  }

  void _inisialisasiWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Warna.tinta)
      ..setUserAgent(_uaMobile)
      ..addJavaScriptChannel(
        'PddiktiVerifikasi',
        onMessageReceived: (JavaScriptMessage message) {
          _prosesPesanJs(message.message);
        },
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
                _statusPesan =
                    'Silakan selesaikan verifikasi CAPTCHA di bawah ini';
              });
            }
            try {
              await _controller.runJavaScript(_jsHookVerifikasi);
            } catch (_) {}
            await _periksaDanAmbilSesi();
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

    // Polling setiap 1,5 detik untuk mengecek apakah user sudah menyelesaikan reCAPTCHA / Cloudflare
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _periksaDanAmbilSesi();
    });
  }

  void _prosesPesanJs(String raw) {
    if (_sudahSelesai) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final token = (decoded['recaptchaToken'] ?? '').toString().trim();
        final cookies = (decoded['cookies'] ?? '').toString().trim();
        final ua = (decoded['userAgent'] ?? '').toString().trim();
        if (token.isNotEmpty) {
          _selesaikanVerifikasi(
            cookies: cookies,
            userAgent: ua,
            recaptchaToken: token,
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _periksaDanAmbilSesi({bool manual = false}) async {
    if (_sudahSelesai) return;
    try {
      final hasilObj = await _controller.runJavaScriptReturningResult('''
        (function() {
          var token = '';
          try {
            if (window.grecaptcha && typeof window.grecaptcha.getResponse === 'function') {
              token = window.grecaptcha.getResponse() || '';
            }
          } catch (_) {}
          if (!token) {
            try {
              var ta = document.querySelector('textarea[name="g-recaptcha-response"]');
              if (ta && ta.value) token = ta.value;
            } catch (_) {}
          }
          return JSON.stringify({
            recaptchaToken: token,
            cookies: document.cookie || '',
            userAgent: navigator.userAgent || ''
          });
        })();
      ''');

      var raw = hasilObj.toString().trim();
      if (raw.startsWith('"') && raw.endsWith('"')) {
        raw = jsonDecode(raw).toString();
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;

      final token = (decoded['recaptchaToken'] ?? '').toString().trim();
      final cookies = (decoded['cookies'] ?? '').toString().trim();
      final ua = (decoded['userAgent'] ?? '').toString().trim();

      if (token.isNotEmpty || cookies.contains('cf_clearance')) {
        _selesaikanVerifikasi(
          cookies: cookies,
          userAgent: ua,
          recaptchaToken: token,
        );
      } else if (manual && mounted) {
        setState(() {
          _statusPesan =
              'CAPTCHA belum terverifikasi. Silakan centang / selesaikan verifikasi di halaman.';
        });
      }
    } catch (_) {}
  }

  void _selesaikanVerifikasi({
    required String cookies,
    required String userAgent,
    String? recaptchaToken,
  }) {
    if (_sudahSelesai) return;
    _sudahSelesai = true;
    _pollingTimer?.cancel();

    ref.read(sesiCloudflareProvider.notifier).simpanSesi(
          cookies: cookies,
          userAgent: userAgent.isNotEmpty ? userAgent : _uaMobile,
          recaptchaToken: recaptchaToken,
        );

    if (mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verifikasi berhasil! Melanjutkan pencarian di aplikasi.'),
          backgroundColor: Warna.laut,
          duration: Duration(seconds: 3),
        ),
      );
    }
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
                const Icon(PhosphorIconsRegular.shieldCheck,
                    size: 20, color: Warna.kunyit),
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
                        'Selesaikan verifikasi CAPTCHA di bawah untuk melanjutkan pencarian di aplikasi.',
                        style: TextStyle(color: Warna.kapurRedup, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.x,
                      size: 18, color: Warna.kapurRedup),
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
                  icon: const Icon(PhosphorIconsRegular.arrowsClockwise,
                      size: 16, color: Warna.kunyit),
                  label: const Text('Muat Ulang Halaman',
                      style: TextStyle(color: Warna.kunyit, fontSize: 12)),
                ),
                ElevatedButton(
                  onPressed: () => _periksaDanAmbilSesi(manual: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Warna.kunyit,
                    foregroundColor: Warna.tinta,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: const Text('Cek Selesai',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
