import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

class GarisTitikPainter extends CustomPainter {
  const GarisTitikPainter({required this.warna});
  final Color warna;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0) return;
    final paint = Paint()
      ..color = warna
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    const jarakTitik = 6.0;
    final y = size.height / 2;
    for (double x = 2; x < size.width - 2; x += jarakTitik) {
      canvas.drawCircle(Offset(x, y), 0.8, paint);
    }
  }

  @override
  bool shouldRepaint(GarisTitikPainter oldDelegate) => oldDelegate.warna != warna;
}

class ItemLedger {
  const ItemLedger({
    required this.label,
    required this.nilai,
    this.nilaiGaya,
    this.onTap,
  });

  final String label;
  final String nilai;
  final TextStyle? nilaiGaya;
  final VoidCallback? onTap;
}

class LedgerWidget extends StatelessWidget {
  const LedgerWidget({
    super.key,
    required this.items,
    this.padding = EdgeInsets.zero,
  });

  final List<ItemLedger> items;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: items.map((item) => _BarisLedger(item: item)).toList(),
      ),
    );
  }
}

class _BarisLedger extends StatelessWidget {
  const _BarisLedger({required this.item});
  final ItemLedger item;

  @override
  Widget build(BuildContext context) {
    final styleNilai = item.nilaiGaya ?? Gaya.angka;
    final styleLabel = Gaya.isi;

    final content = Semantics(
      label: '${item.label}, ${item.nilai}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Ukur apakah label dan nilai muat sebaris
            final textPainterLabel = TextPainter(
              text: TextSpan(text: item.label, style: styleLabel),
              textDirection: TextDirection.ltr,
            )..layout(maxWidth: constraints.maxWidth);

            final textPainterNilai = TextPainter(
              text: TextSpan(text: item.nilai, style: styleNilai),
              textDirection: TextDirection.ltr,
            )..layout(maxWidth: constraints.maxWidth);

            final lebarTotal = textPainterLabel.width + textPainterNilai.width + 32;

            if (lebarTotal > constraints.maxWidth) {
              // Susunan bertumpuk jika tidak muat sebaris (Section 5.4)
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label, style: Gaya.label),
                  const SizedBox(height: 2),
                  Text(item.nilai, style: styleNilai),
                ],
              );
            }

            // Susunan sebaris dengan garis titik-titik
            return Row(
              children: [
                Text(item.label, style: styleLabel),
                const SizedBox(width: 8),
                const Expanded(
                  child: ExcludeSemantics(
                    child: SizedBox(
                      height: 16,
                      child: CustomPaint(
                        painter: GarisTitikPainter(warna: Warna.garisTegas),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.nilai,
                  style: styleNilai,
                  textAlign: TextAlign.right,
                ),
              ],
            );
          },
        ),
      ),
    );

    if (item.onTap != null) {
      return InkWell(
        onTap: item.onTap,
        child: content,
      );
    }
    return content;
  }
}
