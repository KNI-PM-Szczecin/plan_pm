import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

Future<List<String>> loadChangelogForLocale(String version, Locale locale) async {
  final content = await rootBundle.loadString('CHANGELOG.md');
  final localeKey = locale.languageCode == 'pl' ? 'pl-PL' : 'en-US';
  return _parseChangelog(content, version, localeKey);
}

List<String> _parseChangelog(String content, String version, String localeKey) {
  final versionBlocks = content.split(RegExp(r'\n(?=## )', multiLine: true));
  final versionBlock = versionBlocks.firstWhere(
    (b) => b.startsWith('## $version\n'),
    orElse: () => '',
  );
  if (versionBlock.isEmpty) return [];

  final localeBlocks = versionBlock.split(RegExp(r'\n(?=### )', multiLine: true));
  final localeBlock = localeBlocks.firstWhere(
    (b) => b.startsWith('### $localeKey\n'),
    orElse: () => '',
  );
  if (localeBlock.isEmpty) return [];

  return localeBlock
      .split('\n')
      .where((l) => l.startsWith('- '))
      .map((l) => l.substring(2).trim())
      .toList();
}
