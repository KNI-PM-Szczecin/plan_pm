import 'package:flutter_test/flutter_test.dart';
import 'package:plan_pm/pages/news/utils/html_preview.dart';

void main() {
  test('decodes numeric and named entities without decoding twice', () {
    expect(
      htmlPreviewText('A&#39;B &apos;C &#x2014; &copy; &nbsp; &amp;lt;'),
      "A'B 'C — © &lt;",
    );
  });

  test('separates blocks, line breaks, list items and table cells', () {
    expect(
      htmlPreviewText(
        '<div>A</div><div>B<br>C</div><ul><li>D</li><li>E</li></ul>'
        '<table><tr><td>F</td><td>G</td></tr></table>',
      ),
      'A B C D E F G',
    );
  });

  test('preserves inline words and ignores script, style and comments', () {
    expect(
      htmlPreviewText(
        '<p>Po<strong>litechnika</strong> &lt;PM&gt;</p>'
        '<script>hidden()</script><style>.hidden {}</style><!-- comment -->',
      ),
      'Politechnika <PM>',
    );
  });

  test('handles empty and incomplete HTML', () {
    expect(htmlPreviewText(''), '');
    expect(htmlPreviewText('<div>A<p>B'), 'A B');
  });
}
