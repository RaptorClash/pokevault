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
  Timer? _sqliteDebounceTimer;
  Timer? _cloudDebounceTimer;
  Completer<void>? _flushCompleter;

  // Active Timer & AFK Protection
  Timer? _oneSecondTimer;
  String? _activeCounterHuntId;
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

  /// Resets the AFK timer to prevent stopping the encounter session time tracking prematurely.
  void registerInteraction() {
    _lastUserInteraction = DateTime.now();
  }

  /// Loads all shiny hunts from SQLite, merging with any unsaved in-memory hunts.
  Future<void> loadHunts() async {
    if (_pendingDirtyHuntIds.isNotEmpty) {
      await flushPendingWrites();
    }
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

    if (_pendingDirtyHuntIds.isEmpty) {
      if (_flushCompleter != null) {
        await _flushCompleter!.future;
      }
      return;
    }

    final completer = Completer<void>();
    _flushCompleter = completer;
    try {
      final idsToFlush = List<String>.from(_pendingDirtyHuntIds);
      _pendingDirtyHuntIds.clear();

      for (final id in idsToFlush) {
        final hunt = getHuntById(id);
        if (hunt != null) {
          await db.saveShinyHunt(hunt);
        }
      }
    } finally {
      completer.complete();
      if (_flushCompleter == completer) {
        _flushCompleter = null;
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
    detachDexProvider();
    WidgetsBinding.instance.removeObserver(this);
    _sqliteDebounceTimer?.cancel();
    _cloudDebounceTimer?.cancel();
    _oneSecondTimer?.cancel();
    flushPendingWrites();
    super.dispose();
  }
}
