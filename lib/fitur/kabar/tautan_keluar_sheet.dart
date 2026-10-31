import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/tokens.dart';

Future<void> konfirmasiDanBukaTautan(BuildContext context, String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return;

  final host = uri.host.isNotEmpty ? uri.host : url;

  final buka = await showModalBottomSheet<bool>(
    context: context,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Buka $host di peramban?', style: Gaya.judulLayar.copyWith(fontSize: 18)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Buka'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );

  if (buka == true) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

