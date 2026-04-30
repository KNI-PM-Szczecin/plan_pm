import 'package:file/file.dart' hide FileSystem;
import 'package:file/local.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// Cache manager dla obrazków newsów z persystencją do Application Support.
// Standardowy CacheManager zapisuje w tmp/ — iOS może usunąć te pliki pod presją
// pamięci. _PersistentFileSystem przekierowuje zapis do Application Support,
// gdzie pliki przeżywają restart apki. Używany w [NewsCard] i [FullNewsPage].
class _PersistentFileSystem implements FileSystem {
  static const _key = 'news_images';
  static const _localFs = LocalFileSystem();
  late final Future<Directory> _dir = _initDir();

  static Future<Directory> _initDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = _localFs.directory(p.join(base.path, _key));
    await dir.create(recursive: true);
    return dir;
  }

  @override
  Future<File> createFile(String name) async {
    final dir = await _dir;
    if (!(await dir.exists())) await _initDir();
    return dir.childFile(name);
  }
}

final newsCacheManager = CacheManager(
  Config(
    'news_images',
    stalePeriod: const Duration(days: 30),
    maxNrOfCacheObjects: 50,
    fileSystem: _PersistentFileSystem(),
  ),
);
