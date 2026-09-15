// Host-side driver for integration_test. Runs on the machine (not the device),
// so it is the half that can write screenshot bytes to disk.
//
//   flutter drive \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/<name>_test.dart \
//     -d <simulator-udid>

import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      final file = File('screenshots/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      stdout.writeln('screenshot -> ${file.path}');
      return true;
    },
  );
}
