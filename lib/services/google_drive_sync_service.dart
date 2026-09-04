import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

class GoogleDriveSyncService {
  static final GoogleDriveSyncService instance = GoogleDriveSyncService._init();
  GoogleDriveSyncService._init();

  AuthClient? _authClient;
  GoogleSignIn? _webSignIn;
  drive.DriveApi? get _driveApi =>
      _authClient != null ? drive.DriveApi(_authClient!) : null;

  bool get isSignedIn => _authClient != null;

  Future<String> signIn(String clientId, String clientSecret) async {
    clientId = clientId.trim();
    clientSecret = clientSecret.trim();

    // ==========================================
    // 1. WEB LOGIK
    // ==========================================
    if (kIsWeb) {
      try {
        _webSignIn = GoogleSignIn(
          clientId: clientId,
          scopes: [drive.DriveApi.driveAppdataScope],
        );
        final account = await _webSignIn!.signIn();
        if (account != null) {
          _authClient = await _webSignIn!.authenticatedClient();
          if (_authClient != null) return "OK";
        }
        return "Web-Login abgebrochen.";
      } catch (e) {
        return "Web-Login Fehler: $e";
      }
    }

    // ==========================================
    // 2. MOBILE / DESKTOP LOGIK
    // ==========================================
    try {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);

      final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': clientId,
        'redirect_uri': 'http://127.0.0.1:8080',
        'response_type': 'code',
        'scope': drive.DriveApi.driveAppdataScope,
        'access_type': 'offline',
        'prompt': 'consent',
      });

      await launchUrl(authUrl, mode: LaunchMode.externalApplication);

      String? authCode;
      await for (var request in server) {
        if (request.uri.queryParameters.containsKey('code')) {
          authCode = request.uri.queryParameters['code'];
          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.html
            ..write(
              '<html><body><h1 style="color:green; text-align:center; font-family:sans-serif; margin-top:50px;">Login erfolgreich!</h1><p style="text-align:center; font-family:sans-serif;">Du kannst dieses Fenster jetzt schliessen und zurueckkehren.</p></body></html>',
            );
          await request.response.close();
          break;
        } else {
          request.response
            ..statusCode = 400
            ..write('Fehler. Bitte Fenster schliessen.');
          await request.response.close();
          break;
        }
      }
      await server.close(force: true);

      if (authCode == null) {
        return "Kein Autorisierungscode von Google erhalten.";
      }

      await Future.delayed(const Duration(seconds: 1));

      http.Response? tokenResponse;
      String? lastError;

      for (int i = 0; i < 4; i++) {
        try {
          tokenResponse = await http.post(
            Uri.parse('https://oauth2.googleapis.com/token'),
            body: {
              'code': authCode,
              'client_id': clientId,
              'client_secret': clientSecret,
              'redirect_uri': 'http://127.0.0.1:8080',
              'grant_type': 'authorization_code',
            },
          );
          break;
        } catch (e) {
          lastError = e.toString();
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      if (tokenResponse == null) {
        return "Netzwerk blockiert (App war zu lange im Hintergrund): $lastError";
      }

      if (tokenResponse.statusCode == 200) {
        final data = jsonDecode(tokenResponse.body);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('drive_access_token', data['access_token']);
        if (data['refresh_token'] != null) {
          await prefs.setString('drive_refresh_token', data['refresh_token']);
        }
        await prefs.setInt(
          'drive_expiry',
          DateTime.now().millisecondsSinceEpoch +
              ((data['expires_in'] as int) * 1000),
        );

        _createAuthClient(
          clientId,
          clientSecret,
          data['access_token'],
          data['refresh_token'] ?? prefs.getString('drive_refresh_token') ?? '',
          data['expires_in'],
        );
        return "OK";
      } else {
        return "Google lehnte den Login ab: ${tokenResponse.body}";
      }
    } catch (e) {
      return "Lokaler Serverfehler: $e";
    }
  }

  Future<bool> restoreSignIn(String clientId, String clientSecret) async {
    clientId = clientId.trim();
    clientSecret = clientSecret.trim();

    if (kIsWeb) {
      if (clientId.isEmpty) return false;
      try {
        _webSignIn = GoogleSignIn(
          clientId: clientId,
          scopes: [drive.DriveApi.driveAppdataScope],
        );
        final account = await _webSignIn!.signInSilently();
        if (account != null) {
          _authClient = await _webSignIn!.authenticatedClient();
          return _authClient != null;
        }
      } catch (_) {}
      return false;
    }

    if (clientId.isEmpty || clientSecret.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('drive_access_token');
    final refreshToken = prefs.getString('drive_refresh_token');
    final expiry = prefs.getInt('drive_expiry');

    if (accessToken != null && refreshToken != null && expiry != null) {
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiry).toUtc();

      AccessCredentials credentials = AccessCredentials(
        AccessToken('Bearer', accessToken, expiryDate),
        refreshToken,
        [drive.DriveApi.driveAppdataScope],
      );

      _authClient = autoRefreshingClient(
        ClientId(clientId, clientSecret),
        credentials,
        http.Client(),
      );
      return true;
    }
    return false;
  }

  void _createAuthClient(
    String clientId,
    String secret,
    String accessToken,
    String refreshToken,
    int expiresIn,
  ) {
    final expiryDate = DateTime.now().toUtc().add(Duration(seconds: expiresIn));
    AccessCredentials credentials = AccessCredentials(
      AccessToken('Bearer', accessToken, expiryDate),
      refreshToken,
      [drive.DriveApi.driveAppdataScope],
    );
    _authClient = autoRefreshingClient(
      ClientId(clientId, secret),
      credentials,
      http.Client(),
    );
  }

  Future<void> signOut() async {
    if (kIsWeb && _webSignIn != null) {
      await _webSignIn!.signOut();
    }
    _authClient?.close();
    _authClient = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('drive_access_token');
    await prefs.remove('drive_refresh_token');
    await prefs.remove('drive_expiry');
  }

  Future<bool> uploadBackup(Map<String, dynamic> data) async {
    if (_driveApi == null) return false;
    try {
      final jsonStr = jsonEncode(data);
      final List<int> bytes = utf8.encode(jsonStr);
      final stream = Stream.value(bytes);

      final fileList = await _driveApi!.files.list(
        spaces: 'appDataFolder',
        q: "name='pokevault_sync.json'",
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        await _driveApi!.files.update(
          drive.File(),
          fileList.files!.first.id!,
          uploadMedia: drive.Media(stream, bytes.length),
        );
      } else {
        final newFile = drive.File()
          ..name = 'pokevault_sync.json'
          ..parents = ['appDataFolder'];
        await _driveApi!.files.create(
          newFile,
          uploadMedia: drive.Media(stream, bytes.length),
        );
      }
      return true;
    } catch (e) {
      debugPrint("Upload Error: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> downloadBackup() async {
    if (_driveApi == null) return null;
    try {
      final fileList = await _driveApi!.files.list(
        spaces: 'appDataFolder',
        q: "name='pokevault_sync.json'",
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        final fileId = fileList.files!.first.id!;
        final drive.Media media =
            await _driveApi!.files.get(
                  fileId,
                  downloadOptions: drive.DownloadOptions.fullMedia,
                )
                as drive.Media;

        final List<int> bytes = [];
        await for (var chunk in media.stream) {
          bytes.addAll(chunk);
        }
        final jsonStr = utf8.decode(bytes);
        return jsonDecode(jsonStr);
      }
    } catch (e) {
      debugPrint("Download Error: $e");
    }
    return null;
  }

  /// Prüft, ob es in der Cloud eine neuere Version gibt.
  /// Gibt das Datum der letzten Änderung zurück, oder null.
  Future<DateTime?> getRemoteModifiedTime() async {
    if (_driveApi == null) return null;
    try {
      final fileList = await _driveApi!.files.list(
        spaces: 'appDataFolder',
        q: "name='pokevault_sync.json'",
        $fields:
            'files(id, modifiedTime)', // Wir laden NUR die ID und die Zeit herunter!
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        return fileList.files!.first.modifiedTime;
      }
    } catch (e) {
      debugPrint("Metadata Check Error: $e");
    }
    return null;
  }
}
