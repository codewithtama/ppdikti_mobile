import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

/// Sanitizer HTML berbasis daftar putih sesuai spesifikasi bagian 8.2 DESIGN.md.
/// Tag yang diizinkan: p, br, a, strong, b, em, i, u, ul, ol, li, h1..h4.
/// Atribut style, class, align dibuang, hanya href pada tag a yang dipertahankan.
String bersihkanHtml(String rawHtml) {
  if (rawHtml.trim().isEmpty) return '';

  final document = html_parser.parseFragment(rawHtml);
  _sanitasiNode(document);
  return document.outerHtml;
}

const _tagDiizinkan = {
  'p', 'br', 'a', 'strong', 'b', 'em', 'i', 'u', 'ul', 'ol', 'li',
  'h1', 'h2', 'h3', 'h4',
};

void _sanitasiNode(dom.Node node) {
  final nodesToRemove = <dom.Node>[];

  for (final child in node.nodes) {
    if (child is dom.Element) {
      final tagName = child.localName?.toLowerCase() ?? '';
      if (!_tagDiizinkan.contains(tagName)) {
        // Tag tidak diizinkan (misal img, script, iframe, div)
        // Jika memiliki anak teks, angkat anak-anaknya atau buang jika berbahaya
        if (tagName == 'script' || tagName == 'style' || tagName == 'img') {
          nodesToRemove.add(child);
          continue;
        }
      }

      // Bersihkan atribut selain href pada tag 'a'
      final attributes = Map<dynamic, String>.from(child.attributes);
      for (final key in attributes.keys) {
        final keyStr = key.toString();
        if (tagName == 'a' && keyStr == 'href') {
          continue;
        }
        child.attributes.remove(key);
      }

      // Rekursif ke dalam
      _sanitasiNode(child);
    }
  }

  for (final toRemove in nodesToRemove) {
    toRemove.remove();
  }
}

