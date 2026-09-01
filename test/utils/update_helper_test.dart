import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/utils/update_helper.dart';

void main() {
  group('UpdateHelper & UpdateInfo Tests', () {
    test('UpdateInfo Model speichert und mappt Daten korrekt', () {
      final info = UpdateInfo(
        version: 'v1.2.3',
        title: 'Neues Update',
        releaseNotes: 'Viele Fixes',
        downloadUrl: 'https://github.com/test.zip',
        extension: '.zip',
      );

      expect(info.version, equals('v1.2.3'));
      expect(info.title, equals('Neues Update'));
      expect(info.extension, equals('.zip'));
      expect(info.downloadUrl, equals('https://github.com/test.zip'));
    });
  });
}
