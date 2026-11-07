import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' show parseFragment;

/// Dekoduje HTML do zajawki, zachowując odstępy między blokami tekstu.
String htmlPreviewText(String html) {
  final buffer = StringBuffer();
  const separators = {
    'address',
    'article',
    'aside',
    'blockquote',
    'br',
    'dd',
    'details',
    'div',
    'dl',
    'dt',
    'figcaption',
    'figure',
    'footer',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'header',
    'hr',
    'li',
    'main',
    'nav',
    'ol',
    'p',
    'pre',
    'section',
    'summary',
    'table',
    'td',
    'th',
    'tr',
    'ul',
  };

  void append(dom.Node node) {
    if (node is dom.Text) {
      buffer.write(node.data);
      return;
    }
    final tag = node is dom.Element ? node.localName : null;
    if (tag == 'script' || tag == 'style') return;
    final separates = separators.contains(tag);
    if (separates) buffer.write(' ');
    for (final child in node.nodes) {
      append(child);
    }
    if (separates) buffer.write(' ');
  }

  append(parseFragment(html));
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}
