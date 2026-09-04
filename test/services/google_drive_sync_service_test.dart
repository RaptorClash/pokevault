import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/services/google_drive_sync_service.dart';

void main() {
  group('GoogleDriveSyncService Tests', () {
    late GoogleDriveSyncService syncService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      syncService = GoogleDriveSyncService.instance;
    });

    test('Initialzustand: Nicht eingeloggt', () {
      expect(syncService.isSignedIn, isFalse);
    });

    test(
      'restoreSignIn schlägt fehl, wenn keine Tokens gespeichert sind',
      () async {
        bool restored = await syncService.restoreSignIn(
          'test_client_id',
          'test_secret',
        );
        expect(restored, isFalse);
        expect(syncService.isSignedIn, isFalse);
      },
    );

    test('restoreSignIn schlägt fehl bei fehlender Client-ID', () async {
      SharedPreferences.setMockInitialValues({
        'drive_access_token': 'dummy_access',
        'drive_refresh_token': 'dummy_refresh',
        'drive_expiry': DateTime.now()
            .add(const Duration(hours: 1))
            .millisecondsSinceEpoch,
      });

      bool restored = await syncService.restoreSignIn('', 'test_secret');
      expect(restored, isFalse);
    });

    test(
      'restoreSignIn stellt Session erfolgreich wieder her (mit Tokens)',
      () async {
        SharedPreferences.setMockInitialValues({
          'drive_access_token': 'dummy_access',
          'drive_refresh_token': 'dummy_refresh',
          'drive_expiry': DateTime.now()
              .add(const Duration(hours: 1))
              .millisecondsSinceEpoch,
        });

        bool restored = await syncService.restoreSignIn(
          'test_client_id',
          'test_secret',
        );

        expect(restored, isTrue);
        expect(syncService.isSignedIn, isTrue);
      },
    );

    test(
      'signOut löscht alle Tokens aus SharedPreferences und beendet Session',
      () async {
        SharedPreferences.setMockInitialValues({
          'drive_access_token': 'dummy_access',
          'drive_refresh_token': 'dummy_refresh',
          'drive_expiry': DateTime.now()
              .add(const Duration(hours: 1))
              .millisecondsSinceEpoch,
        });
        await syncService.restoreSignIn('test_client_id', 'test_secret');
        expect(syncService.isSignedIn, isTrue);

        await syncService.signOut();

        expect(syncService.isSignedIn, isFalse);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('drive_access_token'), isNull);
        expect(prefs.getString('drive_refresh_token'), isNull);
        expect(prefs.getInt('drive_expiry'), isNull);
      },
    );
  });
}
