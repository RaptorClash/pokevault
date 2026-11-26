import 'dart:async';
import 'package:flutter/widgets.dart';
import '../models/shiny_hunt.dart';
import '../models/pokemon.dart';
import '../services/database_service.dart';
import '../services/google_drive_sync_service.dart';
import 'dex_provider.dart';

/// Provider managing active and archived shiny hunting sessions.
///
/// Features:
/// * In-memory encounter increments with debounced SQLite and cloud persistence.
/// * Real-time hunt stopwatch with automatic AFK pausing and app-lifecycle detection.
/// * Phase tracking and catch dialog orchestration.
/// * Integration with [DexProvider] via upload and merge hooks.
class ShinyHuntProvider extends ChangeNotifier with WidgetsBindingObserver {
  /// The database service used to persist hunt entities.
  final DatabaseService db;
  List<ShinyHunt> _hunts = [];
  bool _isLoading = true;

  // Debouncing & Flush
  final Set<String> _pendingDirtyHuntIds = {};
  final Map<String, int> _loadingDeltaById = {};
  Timer? _sqliteDebounceTimer;
  Timer? _cloudDebounceTimer;
  Future<void>? _flushInFlight;

  // Active Timer & AFK Protection
  Timer? _oneSecondTimer;
  String? _activeCounterHuntId;
  final Set<String> _autoCounterActiveHuntIds = {};
  bool _autoCounterRunningAndUnpaused = false;
  DateTime _lastUserInteraction = DateTime.now();
  bool _isAppInForeground = true;

  Future<void>? _initFuture;

  /// Future that completes when all hunts are loaded from the database.
  Future<void> get initialized => _initFuture ?? Future.value();

  final bool _enableTimer;
  DexProvider? _attachedDexProvider;

  /// Creates a [ShinyHuntProvider] instance.
  ShinyHuntProvider({
    DatabaseService? databaseService,
    bool enableTimer = true,
    DexProvider? dexProvider,
  })  : db = databaseService ?? DatabaseService.instance,
        _enableTimer = enableTimer {
    WidgetsBinding.instance.addObserver(this);
    if (dexProvider != null) {
      attachDexProvider(dexProvider);
    }
    _initFuture = loadHunts();
    if (enableTimer) {
      _startOneSecondTimer();
    }
  }

  /// Attaches a [DexProvider] instance to coordinate cloud upload and merge hooks.
  void attachDexProvider(DexProvider dexProvider) {
    _attachedDexProvider = dexProvider;
    dexProvider.registerBeforeUploadHook(flushPendingWrites);
    dexProvider.registerBeforeMergeHook(flushPendingWrites);
    dexProvider.registerCloudDataMergedHook(loadHunts);
  }

  /// Detaches the currently attached [DexProvider] and removes lifecycle hooks.
  void detachDexProvider() {
    _attachedDexProvider?.unregisterBeforeUploadHook(flushPendingWrites);
    _attachedDexProvider?.unregisterBeforeMergeHook(flushPendingWrites);
    _attachedDexProvider?.unregisterCloudDataMergedHook(loadHunts);
    _attachedDexProvider = null;
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

  /// Returns the ID of the hunt currently linked to the full-screen counter, or null.
  String? get activeCounterHuntId => _activeCounterHuntId;

  /// Sets the currently active hunt ID for the full-screen counter and resets AFK timer.
  void setActiveCounterHunt(String? huntId) {
    _activeCounterHuntId = huntId;
    registerInteraction();
  }

  /// Registers the set of hunts actively tracked by the Shiny Auto-Counter so the
  /// stopwatch keeps ticking across all active slots even when the desktop window is unfocused.
  void setAutoCounterActiveHunts(
    Set<String> huntIds, {
    required bool isRunningAndUnpaused,
  }) {
    _autoCounterActiveHuntIds
      ..clear()
      ..addAll(huntIds);
    _autoCounterRunningAndUnpaused = isRunningAndUnpaused;
  }

  /// Resets the AFK timer to prevent stopping the encounter session time tracking prematurely.
  void registerInteraction() {
    _lastUserInteraction = DateTime.now();
  }

  /// Loads all shiny hunts from SQLite, merging with any unsaved in-memory hunts.
  Future<void> loadHunts() async {
    if (_pendingDirtyHuntIds.isNotEmpty) {
      await flushPendingWrites();
    }
    _loadingDeltaById.clear();
    _isLoading = true;
    notifyListeners();
    try {
      final loaded = await db.getAllShinyHunts();
      final loadedIds = loaded.map((h) => h.id).toSet();
      final inMemoryNew = _hunts.where((h) => !loadedIds.contains(h.id)).toList();
      final merged = [...inMemoryNew, ...loaded];
      if (_loadingDeltaById.isNotEmpty) {
        for (final h in merged) {
          final delta = _loadingDeltaById[h.id];
          if (delta != null && delta != 0) {
            h.currentEncounters =
                (h.currentEncounters + delta).clamp(0, 9999999);
            _pendingDirtyHuntIds.add(h.id);
          }
        }
        _loadingDeltaById.clear();
      }
      _hunts = merged;
    } catch (e) {
      debugPrint('Fehler beim Laden der Shiny Hunts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Inserts a newly created shiny hunt into in-memory state and persists it to the database.
  Future<void> createHunt(ShinyHunt hunt) async {
    _hunts.insert(0, hunt);
    notifyListeners();
    await db.saveShinyHunt(hunt);
    _triggerCloudSyncLater();
  }

  /// Updates an existing shiny hunt's metadata and persists changes to the database.
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

  /// Increments the encounter count of the specified hunt by its configured step size.
  void increment(String huntId) {
    final hunt = getHuntById(huntId);
    if (hunt == null || hunt.isCompleted) return;

    if (hunt.isPaused) {
      hunt.status = 'active';
      if (hunt.pauseHistory.isNotEmpty && hunt.pauseHistory.last.resumedAt == null) {
        hunt.pauseHistory.last.resumedAt = DateTime.now();
      }
    }
    hunt.currentEncounters += hunt.incrementStep;
    hunt.updatedAt = DateTime.now();
    registerInteraction();
    notifyListeners();
    _markDirtyAndDebounce(huntId);
  }

  /// Decrements the encounter count of the specified hunt, clamping at zero.
  void decrement(String huntId) {
    final hunt = getHuntById(huntId);
    if (hunt == null || hunt.isCompleted) return;

    hunt.currentEncounters = (hunt.currentEncounters - hunt.incrementStep).clamp(0, 9999999);
    hunt.updatedAt = DateTime.now();
    registerInteraction();
    notifyListeners();
    _markDirtyAndDebounce(huntId);
  }

  /// Automatically increments the encounter count by an explicit [delta] (e.g. from OCR/camera).
  ///
  /// Resets the AFK interaction timer so hunt duration tracking stays active while auto-hunting.
  void incrementAuto(
    String huntId, {
    int? delta,
    bool resumeIfPaused = false,
  }) {
    final hunt = getHuntById(huntId);
    if (hunt == null || hunt.isCompleted) return;
    final stepDelta = (delta ?? hunt.incrementStep).clamp(1, 9999999);

    if (hunt.isPaused) {
      if (!resumeIfPaused) return;
      hunt.status = 'active';
      if (hunt.pauseHistory.isNotEmpty && hunt.pauseHistory.last.resumedAt == null) {
        hunt.pauseHistory.last.resumedAt = DateTime.now();
      }
    }

    hunt.currentEncounters = (hunt.currentEncounters + stepDelta).clamp(0, 9999999);
    hunt.updatedAt = DateTime.now();
    if (_isLoading) {
      _loadingDeltaById[huntId] = (_loadingDeltaById[huntId] ?? 0) + stepDelta;
    }
    registerInteraction();
    notifyListeners();
    _markDirtyAndDebounce(huntId);
  }

  /// Automatically decrements the encounter count by [delta] (e.g. for Auto-Counter Undo), clamping at zero.
  void decrementAuto(String huntId, {int delta = 1}) {
    final hunt = getHuntById(huntId);
    if (hunt == null || hunt.isCompleted || delta <= 0) return;

    hunt.currentEncounters = (hunt.currentEncounters - delta).clamp(0, 9999999);
    hunt.updatedAt = DateTime.now();
    if (_isLoading) {
      _loadingDeltaById[huntId] = (_loadingDeltaById[huntId] ?? 0) - delta;
    }
    registerInteraction();
    notifyListeners();
    _markDirtyAndDebounce(huntId);
  }

  /// Sets the increment step size (e.g. 1, 5) for encounter counting.
  void setStep(String huntId, int newStep) {
    final hunt = getHuntById(huntId);
    if (hunt == null || newStep <= 0) return;

    hunt.incrementStep = newStep;
    hunt.updatedAt = DateTime.now();
    notifyListeners();
    _markDirtyAndDebounce(huntId);
  }

  /// Manually overrides the encounter count of the specified hunt.
  void setManualCount(String huntId, int newCount) {
    final hunt = getHuntById(huntId);
    if (hunt == null) return;

    hunt.currentEncounters = newCount.clamp(0, 9999999);
    hunt.updatedAt = DateTime.now();
    registerInteraction();
    notifyListeners();
    _markDirtyAndDebounce(huntId);
  }

  /// Pauses an active hunt, flushes dirty writes, and triggers cloud sync.
  Future<void> pauseHunt(String huntId) async {
    final hunt = getHuntById(huntId);
    if (hunt == null) return;

    if (hunt.status != 'paused') {
      hunt.status = 'paused';
      final intervals = List<ShinyPauseInterval>.from(hunt.pauseHistory);
      intervals.add(ShinyPauseInterval(pausedAt: DateTime.now()));
      hunt.pauseHistory = intervals;
    }
    hunt.updatedAt = DateTime.now();
    notifyListeners();
    await flushPendingWrites();
    await db.saveShinyHunt(hunt);
    _triggerCloudSyncLater(immediate: true);
  }

  /// Resumes a paused hunt and resets interaction timestamp.
  Future<void> resumeHunt(String huntId) async {
    final hunt = getHuntById(huntId);
    if (hunt == null) return;

    if (hunt.isPaused) {
      hunt.status = 'active';
      if (hunt.pauseHistory.isNotEmpty && hunt.pauseHistory.last.resumedAt == null) {
        hunt.pauseHistory.last.resumedAt = DateTime.now();
      }
    }
    hunt.updatedAt = DateTime.now();
    registerInteraction();
    notifyListeners();
    await db.saveShinyHunt(hunt);
  }

  /// Records an unintended shiny encounter (phase), archiving encounters and incrementing phase count.
  ///
  /// Optionally marks the phased Pokémon as caught & shiny in the specified Pokédex.
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
      final poke = dexProvider.allPokemon.where((p) => p.id == caughtPokemonId).firstOrNull;
      final formName = poke?.forms.firstOrNull?.name ?? 'normal';
      await dexProvider.markPokemonCaughtAndShiny(targetDexId, '${caughtPokemonId}_$formName');
    }

    notifyListeners();
    await db.saveShinyHunt(hunt);
    _triggerCloudSyncLater(immediate: true);
  }

  /// Marks a hunt as completed, records completion timestamp and Pokéball used.
  ///
  /// If [targetDexId] and [dexProvider] are supplied, marks the Pokémon caught and shiny in the Pokédex.
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
    if (hunt.pauseHistory.isNotEmpty && hunt.pauseHistory.last.resumedAt == null) {
      hunt.pauseHistory.last.resumedAt = DateTime.now();
    }
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
      String uid = targetUniqueId ?? hunt.targetUniqueId ?? '';
      if (uid.isEmpty || !uid.contains('_')) {
        final poke = dexProvider.allPokemon.where((p) => p.id == hunt.pokemonId).firstOrNull;
        PokemonForm? form;
        if (hunt.pokemonFormId != null && hunt.pokemonFormId! > 0) {
          form = poke?.forms.where((f) => (f.imageId > 0 ? f.imageId : poke.id) == hunt.pokemonFormId).firstOrNull;
        }
        form ??= poke?.forms.firstOrNull;
        if (form != null) {
          uid = '${hunt.pokemonId}_${form.name}';
        } else {
          uid = '${hunt.pokemonId}_normal';
        }
      }

      hunt.targetDexId = targetDexId;
      hunt.targetUniqueId = uid;

      await dexProvider.markPokemonCaughtAndShiny(targetDexId, uid);
    }

    notifyListeners();
    await db.saveShinyHunt(hunt);
    _triggerCloudSyncLater(immediate: true);
  }

  /// Reopens a previously completed hunt, returning its status to active.
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

  /// Deletes a hunt either via soft-delete timestamp or permanent SQLite removal.
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

  /// Immediately flushes all debounced in-memory counter changes to SQLite.
  Future<void> flushPendingWrites() async {
    _sqliteDebounceTimer?.cancel();
    _sqliteDebounceTimer = null;

    if (_flushInFlight != null) {
      await _flushInFlight;
      if (_pendingDirtyHuntIds.isEmpty) return;
    }

    Future<void> runFlush() async {
      while (_pendingDirtyHuntIds.isNotEmpty) {
        final idsToFlush = List<String>.from(_pendingDirtyHuntIds);
        _pendingDirtyHuntIds.clear();

        for (int i = 0; i < idsToFlush.length; i++) {
          final id = idsToFlush[i];
          final hunt = getHuntById(id);
          if (hunt == null) continue;
          try {
            await db.saveShinyHunt(hunt);
          } catch (_) {
            _pendingDirtyHuntIds.addAll(idsToFlush.sublist(i));
            rethrow;
          }
        }
      }
    }

    final future = runFlush();
    _flushInFlight = future;
    try {
      await future;
    } finally {
      if (identical(_flushInFlight, future)) {
        _flushInFlight = null;
      }
    }
  }

  Future<void> _executeCloudUpload() async {
    try {
      if (GoogleDriveSyncService.instance.isSignedIn) {
        await flushPendingWrites();
        final exportData = await db.exportCloudSyncData();
        await GoogleDriveSyncService.instance.uploadBackup(exportData);
      }
    } catch (e) {
      debugPrint('ShinyHuntProvider Silent Upload Error: $e');
    }
  }

  void _triggerCloudSyncLater({bool immediate = false}) {
    if (!_enableTimer) return;
    if (_attachedDexProvider != null) {
      if (immediate) {
        flushPendingWrites().then((_) {
          _attachedDexProvider?.triggerAutoUpload();
        });
      } else {
        _attachedDexProvider!.triggerAutoUpload();
      }
      return;
    }
    _cloudDebounceTimer?.cancel();
    if (immediate) {
      _executeCloudUpload();
      return;
    }
    // Entkoppelter Cloud Sync Debounce (3 Sekunden)
    _cloudDebounceTimer = Timer(const Duration(seconds: 3), () {
      _executeCloudUpload();
    });
  }

  // --- 1-Sekunden-Timer mit AFK-Schutz ---

  void _startOneSecondTimer() {
    _oneSecondTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final hasActiveAuto =
          _autoCounterRunningAndUnpaused && _autoCounterActiveHuntIds.isNotEmpty;
      if (!_isAppInForeground && !hasActiveAuto) return;

      // AFK-Schutz: Nach 3 Minuten ohne Tap/Auto-Encounter stoppt die Zeiterfassung
      final isAfk = DateTime.now().difference(_lastUserInteraction) >
          const Duration(minutes: 3);
      if (isAfk) return;

      final targetIds = <String>{
        if (_isAppInForeground && _activeCounterHuntId != null)
          _activeCounterHuntId!,
        if (hasActiveAuto) ..._autoCounterActiveHuntIds,
      };
      bool changed = false;
      for (final id in targetIds) {
        final hunt = getHuntById(id);
        if (hunt != null && hunt.isActive) {
          hunt.totalTimeSeconds += 1;
          changed = true;
          // Nicht jede einzelne Sekunde auf Flash schreiben: Alle 10s debouncen
          if (hunt.totalTimeSeconds % 10 == 0) {
            _markDirtyAndDebounce(hunt.id);
          }
        }
      }
      if (changed) {
        notifyListeners();
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
    detachDexProvider();
    WidgetsBinding.instance.removeObserver(this);
    _sqliteDebounceTimer?.cancel();
    _cloudDebounceTimer?.cancel();
    _oneSecondTimer?.cancel();
    flushPendingWrites();
    super.dispose();
  }
}
