import 'dart:async';
import 'package:flutter/widgets.dart';
import '../models/shiny_hunt.dart';
import '../services/database_service.dart';
import '../services/google_drive_sync_service.dart';
import 'dex_provider.dart';

class ShinyHuntProvider extends ChangeNotifier with WidgetsBindingObserver {
  final DatabaseService db;
  List<ShinyHunt> _hunts = [];
  bool _isLoading = true;

  // Debouncing & Flush
  final Set<String> _pendingDirtyHuntIds = {};
  Timer? _sqliteDebounceTimer;
  Timer? _cloudDebounceTimer;

  // Active Timer & AFK Protection
  Timer? _oneSecondTimer;
  String? _activeCounterHuntId;
  DateTime _lastUserInteraction = DateTime.now();
  bool _isAppInForeground = true;

  Future<void>? _initFuture;
  Future<void> get initialized => _initFuture ?? Future.value();

  final bool _enableTimer;

  ShinyHuntProvider({DatabaseService? databaseService, bool enableTimer = true})
      : db = databaseService ?? DatabaseService.instance,
        _enableTimer = enableTimer {
    WidgetsBinding.instance.addObserver(this);
    _initFuture = loadHunts();
    if (enableTimer) {
      _startOneSecondTimer();
    }
  }

  bool get isLoading => _isLoading;
  List<ShinyHunt> get hunts => _hunts;

  List<ShinyHunt> get activeHunts =>
      _hunts.where((h) => h.status == 'active' && h.deletedAt == 0).toList();

  List<ShinyHunt> get pausedHunts =>
      _hunts.where((h) => h.status == 'paused' && h.deletedAt == 0).toList();

  List<ShinyHunt> get completedHunts =>
      _hunts.where((h) => h.status == 'completed' && h.deletedAt == 0).toList();

  ShinyHunt? getHuntById(String id) {
    try {
      return _hunts.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }

  String? get activeCounterHuntId => _activeCounterHuntId;

  void setActiveCounterHunt(String? huntId) {
    _activeCounterHuntId = huntId;
    registerInteraction();
  }

  void registerInteraction() {
    _lastUserInteraction = DateTime.now();
  }

  Future<void> loadHunts() async {
    _isLoading = true;
    notifyListeners();
    try {
      final loaded = await db.getAllShinyHunts();
      final loadedIds = loaded.map((h) => h.id).toSet();
      final inMemoryNew = _hunts.where((h) => !loadedIds.contains(h.id)).toList();
      _hunts = [...inMemoryNew, ...loaded];
    } catch (e) {
      debugPrint('Fehler beim Laden der Shiny Hunts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createHunt(ShinyHunt hunt) async {
    _hunts.insert(0, hunt);
    notifyListeners();
    await db.saveShinyHunt(hunt);
    _triggerCloudSyncLater();
  }

  Future<void> updateHunt(ShinyHunt hunt) async {
    final index = _hunts.indexWhere((h) => h.id == hunt.id);
    if (index != -1) {
      hunt.updatedAt = DateTime.now();
      _hunts[index] = hunt;
      notifyListeners();
      await db.saveShinyHunt(hunt);
      _triggerCloudSyncLater();
    }
  }

  void increment(String huntId) {
    final hunt = getHuntById(huntId);
    if (hunt == null || hunt.isCompleted) return;

    if (hunt.isPaused) {
      hunt.status = 'active';
    }
    hunt.currentEncounters += hunt.incrementStep;
    hunt.updatedAt = DateTime.now();
    registerInteraction();
    notifyListeners();
    _markDirtyAndDebounce(huntId);
  }

  void decrement(String huntId) {
    final hunt = getHuntById(huntId);
    if (hunt == null || hunt.isCompleted) return;

    hunt.currentEncounters = (hunt.currentEncounters - hunt.incrementStep).clamp(0, 9999999);
    hunt.updatedAt = DateTime.now();
    registerInteraction();
    notifyListeners();
    _markDirtyAndDebounce(huntId);
  }

  void setStep(String huntId, int newStep) {
    final hunt = getHuntById(huntId);
    if (hunt == null || newStep <= 0) return;

    hunt.incrementStep = newStep;
    hunt.updatedAt = DateTime.now();
    notifyListeners();
    _markDirtyAndDebounce(huntId);
  }

  void setManualCount(String huntId, int newCount) {
    final hunt = getHuntById(huntId);
    if (hunt == null) return;

    hunt.currentEncounters = newCount.clamp(0, 9999999);
    hunt.updatedAt = DateTime.now();
    registerInteraction();
    notifyListeners();
    _markDirtyAndDebounce(huntId);
  }

  Future<void> pauseHunt(String huntId) async {
    final hunt = getHuntById(huntId);
    if (hunt == null) return;

    hunt.status = 'paused';
    hunt.updatedAt = DateTime.now();
    notifyListeners();
    await flushPendingWrites();
    await db.saveShinyHunt(hunt);
    _triggerCloudSyncLater(immediate: true);
  }

  Future<void> resumeHunt(String huntId) async {
    final hunt = getHuntById(huntId);
    if (hunt == null) return;

    hunt.status = 'active';
    hunt.updatedAt = DateTime.now();
    registerInteraction();
    notifyListeners();
    await db.saveShinyHunt(hunt);
  }

  Future<void> recordPhaseShiny(
    String huntId, {
    String? caughtPokemonName,
    int? caughtPokemonId,
    bool syncToDex = false,
    String? targetDexId,
    DexProvider? dexProvider,
  }) async {
    final hunt = getHuntById(huntId);
    if (hunt == null) return;

    final entry = ShinyPhaseEntry(
      phaseNumber: hunt.phase,
      encounters: hunt.currentEncounters,
      caughtPokemonId: caughtPokemonId,
      caughtPokemonName: caughtPokemonName,
      completedAt: DateTime.now(),
    );

    hunt.phaseHistory.add(entry);
    hunt.priorPhaseEncounters += hunt.currentEncounters;
    hunt.currentEncounters = 0;
    hunt.phase += 1;
    hunt.updatedAt = DateTime.now();

    if (syncToDex && targetDexId != null && dexProvider != null && caughtPokemonId != null) {
      await dexProvider.markPokemonCaughtAndShiny(targetDexId, caughtPokemonId.toString());
    }

    notifyListeners();
    await db.saveShinyHunt(hunt);
    _triggerCloudSyncLater(immediate: true);
  }

  Future<void> completeHunt(
    String huntId, {
    String? ballUsed,
    String? targetDexId,
    String? targetUniqueId,
    DexProvider? dexProvider,
    String? notes,
  }) async {
    final hunt = getHuntById(huntId);
    if (hunt == null) return;

    hunt.status = 'completed';
    if (ballUsed != null) {
      hunt.ballUsed = ballUsed;
    }
    hunt.completedAt = DateTime.now();
    hunt.updatedAt = DateTime.now();
    if (notes != null && notes.trim().isNotEmpty) {
      hunt.notes = hunt.notes != null && hunt.notes!.isNotEmpty
          ? '${hunt.notes}\n$notes'
          : notes;
    }

    if (targetDexId != null && dexProvider != null) {
      String uid = targetUniqueId ?? hunt.pokemonId.toString();
      if (targetUniqueId == null && hunt.pokemonFormId != null && hunt.pokemonFormId! > 0) {
        final poke = dexProvider.allPokemon.where((p) => p.id == hunt.pokemonId).firstOrNull;
        final form = poke?.forms.where((f) => (f.imageId > 0 ? f.imageId : poke.id) == hunt.pokemonFormId).firstOrNull;
        if (form != null && form.name != 'normal') {
          uid = '${hunt.pokemonId}_${form.name}';
        }
      }
      await dexProvider.markPokemonCaughtAndShiny(targetDexId, uid);
    }

    notifyListeners();
    await db.saveShinyHunt(hunt);
    _triggerCloudSyncLater(immediate: true);
  }

  Future<void> reopenHunt(String huntId) async {
    final hunt = getHuntById(huntId);
    if (hunt == null) return;

    hunt.status = 'active';
    hunt.completedAt = null;
    hunt.ballUsed = null;
    hunt.updatedAt = DateTime.now();
    registerInteraction();
    notifyListeners();
    await db.saveShinyHunt(hunt);
    _triggerCloudSyncLater(immediate: true);
  }

  Future<void> deleteHunt(String huntId, {bool softDelete = true}) async {
    _pendingDirtyHuntIds.remove(huntId);
    if (_activeCounterHuntId == huntId) {
      _activeCounterHuntId = null;
    }
    final index = _hunts.indexWhere((h) => h.id == huntId);
    if (index != -1) {
      if (softDelete) {
        _hunts[index].deletedAt = DateTime.now().toUtc().millisecondsSinceEpoch;
        _hunts.removeAt(index);
      } else {
        _hunts.removeAt(index);
      }
      notifyListeners();
      await db.deleteShinyHunt(huntId, softDelete: softDelete);
      _triggerCloudSyncLater(immediate: true);
    }
  }

  // --- SQLite Debounce & Flush ---

  void _markDirtyAndDebounce(String huntId) {
    _pendingDirtyHuntIds.add(huntId);
    if (!_enableTimer) {
      flushPendingWrites();
      return;
    }
    _sqliteDebounceTimer?.cancel();
    _sqliteDebounceTimer = Timer(const Duration(milliseconds: 250), () {
      flushPendingWrites();
    });
    _triggerCloudSyncLater();
  }

  Future<void> flushPendingWrites() async {
    _sqliteDebounceTimer?.cancel();
    _sqliteDebounceTimer = null;

    if (_pendingDirtyHuntIds.isEmpty) return;

    final idsToFlush = List<String>.from(_pendingDirtyHuntIds);
    _pendingDirtyHuntIds.clear();

    for (final id in idsToFlush) {
      final hunt = getHuntById(id);
      if (hunt != null) {
        await db.saveShinyHunt(hunt);
      }
    }
  }

  Future<void> _executeCloudUpload() async {
    try {
      if (GoogleDriveSyncService.instance.isSignedIn) {
        final exportData = await db.exportCloudSyncData();
        await GoogleDriveSyncService.instance.uploadBackup(exportData);
      }
    } catch (e) {
      debugPrint('ShinyHuntProvider Silent Upload Error: $e');
    }
  }

  void _triggerCloudSyncLater({bool immediate = false}) {
    _cloudDebounceTimer?.cancel();
    if (!_enableTimer) return;
    if (immediate) {
      _executeCloudUpload();
      return;
    }
    // Entkoppelter Cloud Sync Debounce (30 Sekunden nach dem letzten Tap)
    _cloudDebounceTimer = Timer(const Duration(seconds: 30), () {
      _executeCloudUpload();
    });
  }

  // --- 1-Sekunden-Timer mit AFK-Schutz ---

  void _startOneSecondTimer() {
    _oneSecondTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isAppInForeground) return;

      // AFK-Schutz: Nach 3 Minuten ohne Tap stoppt die Zeiterfassung
      final isAfk = DateTime.now().difference(_lastUserInteraction) > const Duration(minutes: 3);
      if (isAfk) return;

      if (_activeCounterHuntId != null) {
        final hunt = getHuntById(_activeCounterHuntId!);
        if (hunt != null && hunt.isActive) {
          hunt.totalTimeSeconds += 1;
          notifyListeners();
          // Nicht jede einzelne Sekunde auf Flash schreiben: Alle 10s debouncen
          if (hunt.totalTimeSeconds % 10 == 0) {
            _markDirtyAndDebounce(hunt.id);
          }
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isAppInForeground = true;
      registerInteraction();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _isAppInForeground = false;
      // Pflicht-Flush bei App-Hintergrundwechsel!
      flushPendingWrites();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sqliteDebounceTimer?.cancel();
    _cloudDebounceTimer?.cancel();
    _oneSecondTimer?.cancel();
    flushPendingWrites();
    super.dispose();
  }
}
