import 'dart:async';
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:material_ui/material_ui.dart';
import '../../../i18n/strings.g.dart';
import '../../../services/desktop_tracker/desktop_capture_driver.dart';
import '../../../services/desktop_tracker/windows_desktop_bridge.dart';
import '../../../services/scanner_core/engine/ocr_detection_engine.dart';
import '../../../services/scanner_core/engine/pokemon_fuzzy_matcher.dart';
import '../../../services/scanner_core/media/image_frame_decoder.dart';
import '../../../services/scanner_core/models/scanner_event.dart';
import '../../../services/scanner_core/models/scanner_settings.dart';

/// Studio modal for creating, deduplicating, testing (Text & Photo), and managing custom OCR patterns.
class CustomPatternStudioDialog extends StatefulWidget {
  final List<CustomOcrPattern> initialPatterns;
  final PokemonFuzzyMatcher matcher;
  final OcrPreprocessProfile initialProfile;
  final CapturedFrame? latestLiveFrame;
  final ValueChanged<List<CustomOcrPattern>> onPatternsChanged;
  final Future<CapturedFrame?> Function()? sandboxImagePicker;
  final Future<OcrRecognitionResult> Function(
    CapturedFrame frame,
    OcrPreprocessProfile profile,
  )? onRunPhotoOcr;

  const CustomPatternStudioDialog({
    super.key,
    required this.initialPatterns,
    required this.matcher,
    required this.initialProfile,
    required this.onPatternsChanged,
    this.latestLiveFrame,
    this.sandboxImagePicker,
    this.onRunPhotoOcr,
  });

  @override
  State<CustomPatternStudioDialog> createState() =>
      _CustomPatternStudioDialogState();
}

class _CustomPatternStudioDialogState extends State<CustomPatternStudioDialog> {
  late List<CustomOcrPattern> _patterns;
  final TextEditingController _templateController = TextEditingController();
  final TextEditingController _sandboxController = TextEditingController();
  ScannerEventType _selectedType = ScannerEventType.caught;
  int _sandboxTabIndex = 0; // 0 = Text Sandbox, 1 = Photo / Frame Sandbox

  CapturedFrame? _sandboxFrame;
  OcrPreprocessProfile _sandboxProfile = OcrPreprocessProfile.pixelArtDs;
  bool _runningPhotoOcr = false;
  int _photoOcrRunId = 0;
  String? _photoError;
  Map<OcrPreprocessProfile, OcrRecognitionResult> _photoResults = const {};

  String _sandboxRawText = '';
  String? _duplicateHint;

  @override
  void initState() {
    super.initState();
    _patterns = List<CustomOcrPattern>.from(widget.initialPatterns);
    _sandboxProfile = widget.initialProfile;
    _sandboxFrame = widget.latestLiveFrame;
  }

  @override
  void dispose() {
    _photoOcrRunId++;
    _templateController.dispose();
    _sandboxController.dispose();
    super.dispose();
  }

  void _commitPatterns() {
    widget.onPatternsChanged(List<CustomOcrPattern>.unmodifiable(_patterns));
  }

  void _addPattern(String rawTemplate, ScannerEventType eventType) {
    final trimmed = rawTemplate.trim();
    if (trimmed.isEmpty || !trimmed.contains('{pokemon}')) {
      setState(() {
        _duplicateHint = t.scanner_pattern_missing_placeholder;
      });
      return;
    }

    final normNew = trimmed.toLowerCase();
    final exists = _patterns.any(
      (p) => p.template.trim().toLowerCase() == normNew && p.eventType == eventType,
    );
    if (exists) {
      setState(() {
        _duplicateHint =
            t.scanner_pattern_duplicate.replaceAll('{template}', trimmed);
      });
      return;
    }

    setState(() {
      _duplicateHint = null;
      _patterns.add(
        CustomOcrPattern(
          id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
          template: trimmed,
          eventType: eventType,
          enabled: true,
        ),
      );
    });
    _commitPatterns();
  }

  void _insertToken(String token) {
    final text = _templateController.text;
    final selection = _templateController.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final needsLeadingSpace = start > 0 && text[start - 1] != ' ';
    final inserted = needsLeadingSpace ? ' $token' : token;
    final nextText = text.replaceRange(start, end, inserted);
    _templateController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: start + inserted.length),
    );
  }

  ({
    OcrParseResult? parsed,
    List<FuzzyMatchResult> matches,
    bool isSmart,
  }) _evaluateSandboxText(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return (parsed: null, matches: const [], isSmart: false);
    }

    final engine = OcrDetectionEngine()..updateCustomPatterns(_patterns);
    final parsed = engine.parse(trimmed);
    if (parsed == null) {
      return (parsed: null, matches: const [], isSmart: false);
    }

    List<FuzzyMatchResult> matches;
    if (parsed.isSmartSearchFallback) {
      matches = widget.matcher.matchTokensFromLine(
        parsed.extractedPokemonName,
        limit: 3,
        threshold: 0.72,
      );
    } else {
      matches = widget.matcher.matchTopK(
        parsed.extractedPokemonName,
        limit: 3,
        threshold: 0.72,
      );
      if (matches.isEmpty && parsed.extractedPokemonName.contains(' ')) {
        matches = widget.matcher.matchTokensFromLine(
          parsed.extractedPokemonName,
          limit: 3,
          threshold: 0.72,
        );
      }
    }

    final isSmart = parsed.isSmartSearchFallback ||
        (matches.isNotEmpty && matches.first.confidence < 1.0);
    return (parsed: parsed, matches: matches, isSmart: isSmart);
  }

  Future<void> _pickPhotoFrame() async {
    setState(() {
      _photoError = null;
    });
    try {
      CapturedFrame? frame;
      if (widget.sandboxImagePicker != null) {
        frame = await widget.sandboxImagePicker!();
      } else {
        final typeGroup = XTypeGroup(
          label: t.scanner_pattern_images_label,
          extensions: const ['png', 'jpg', 'jpeg', 'webp', 'bmp'],
        );
        final file = await openFile(acceptedTypeGroups: [typeGroup]);
        if (file == null) return;
        final Uint8List bytes = await file.readAsBytes();
        frame = await ImageFrameDecoder.decodeBytesToBgraFrame(bytes);
      }

      if (!mounted) return;
      if (frame == null) {
        setState(() {
          _photoError = t.scanner_pattern_decode_failed;
        });
        return;
      }
      setState(() {
        _sandboxFrame = frame;
        _photoResults = const {};
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _photoError = t.scanner_pattern_load_error.replaceAll('{error}', '$e');
      });
    }
  }

  Future<void> _runPhotoOcr({bool compareAll = false}) async {
    final frame = _sandboxFrame;
    if (frame == null || widget.onRunPhotoOcr == null) return;
    final runId = ++_photoOcrRunId;
    setState(() {
      _runningPhotoOcr = true;
      _photoError = null;
    });

    try {
      final profilesToRun = compareAll
          ? OcrPreprocessProfile.values
          : <OcrPreprocessProfile>[_sandboxProfile];
      final results = <OcrPreprocessProfile, OcrRecognitionResult>{};
      for (final p in profilesToRun) {
        if (!mounted || runId != _photoOcrRunId) return;
        final res = await widget.onRunPhotoOcr!(frame, p);
        if (!mounted || runId != _photoOcrRunId) return;
        results[p] = res;
      }
      if (!mounted || runId != _photoOcrRunId) return;
      setState(() {
        _photoResults = results;
        final activeText = (results[_sandboxProfile]?.lines ??
                results.values.firstOrNull?.lines ??
                const [])
            .join('\n');
        if (activeText.isNotEmpty) {
          _sandboxRawText = activeText;
          _sandboxController.text = activeText;
        }
      });
    } catch (e) {
      if (!mounted || runId != _photoOcrRunId) return;
      setState(() {
        _photoError = t.scanner_pattern_ocr_error.replaceAll('{error}', '$e');
      });
    } finally {
      if (mounted && runId == _photoOcrRunId) {
        setState(() {
          _runningPhotoOcr = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF171825) : Colors.white;
    final cardBg = isDark ? const Color(0xFF202235) : const Color(0xFFF6F7FB);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);
    final eval = _evaluateSandboxText(_sandboxRawText);

    return Dialog(
      key: const Key('custom_patterns_dialog'),
      backgroundColor: bg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 780),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_fix_high_rounded,
                    color: Colors.deepPurpleAccent,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Eigene OCR-Muster & Scan-Studio',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Muster ohne Duplikate pflegen & gegen echten OCR-Text oder Fotos testen',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Schließen',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: borderColor),

            // Scrollable Studio Cards
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // CARD 1: Pattern Composer & Deduplicated Quick Templates
                    _buildCard(
                      cardBg: cardBg,
                      borderColor: borderColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NEUES MUSTER DEFINIEREN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildTypeSegmentPill(
                                key: const Key('type_pill_caught'),
                                type: ScannerEventType.caught,
                                label: 'Gefangen',
                                color: Colors.greenAccent,
                              ),
                              _buildTypeSegmentPill(
                                key: const Key('type_pill_encounter'),
                                type: ScannerEventType.encounter,
                                label: 'Begegnung',
                                color: Colors.amberAccent,
                              ),
                              _buildTypeSegmentPill(
                                key: const Key('type_pill_evolved'),
                                type: ScannerEventType.evolved,
                                label: 'Entwicklung',
                                color: Colors.lightBlueAccent,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minWidth: 200,
                                  maxWidth: 480,
                                ),
                                child: TextField(
                                  key: const Key('custom_pattern_input'),
                                  controller: _templateController,
                                  decoration: InputDecoration(
                                    hintText:
                                        'z. B. Klasse! {pokemon} * gefangen',
                                    isDense: true,
                                    filled: true,
                                    fillColor: isDark
                                        ? const Color(0xFF141522)
                                        : Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                key: const Key('btn_add_custom_pattern'),
                                onPressed: () {
                                  _addPattern(
                                    _templateController.text,
                                    _selectedType,
                                  );
                                  if (_duplicateHint == null) {
                                    _templateController.clear();
                                  }
                                },
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Hinzufügen'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Bausteine:',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              ActionChip(
                                label: const Text('+ {pokemon}',
                                    style: TextStyle(fontSize: 11)),
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _insertToken('{pokemon}'),
                              ),
                              ActionChip(
                                label: const Text('+ * (Platzhalter)',
                                    style: TextStyle(fontSize: 11)),
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _insertToken('*'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Schnellvorlagen (werden automatisch dedupliziert):',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildQuickPresetChip(
                                key: const Key('quick_pat_klasse'),
                                template: 'Klasse! {pokemon}',
                                eventType: ScannerEventType.caught,
                              ),
                              _buildQuickPresetChip(
                                key: const Key('quick_pat_caught'),
                                template: '{pokemon} gefangen',
                                eventType: ScannerEventType.caught,
                              ),
                              _buildQuickPresetChip(
                                key: const Key('quick_pat_wild'),
                                template: 'Wildes {pokemon} erscheint',
                                eventType: ScannerEventType.encounter,
                              ),
                            ],
                          ),
                          if (_duplicateHint != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _duplicateHint!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.amber,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // CARD 2: Live Sandbox (Text + Photo / Frame)
                    _buildCard(
                      cardBg: cardBg,
                      borderColor: borderColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'LIVE-SANDBOX TESTEN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                  color: Colors.grey,
                                ),
                              ),
                              Wrap(
                                spacing: 6,
                                children: [
                                  _buildSandboxTabPill(
                                    key: const Key('sandbox_tab_text'),
                                    index: 0,
                                    icon: Icons.text_fields_rounded,
                                    label: 'Text testen',
                                  ),
                                  _buildSandboxTabPill(
                                    key: const Key('sandbox_tab_photo'),
                                    index: 1,
                                    icon: Icons.image_search_rounded,
                                    label: 'Foto / Frame testen',
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_sandboxTabIndex == 0) ...[
                            TextField(
                              key: const Key('sandbox_text_input'),
                              controller: _sandboxController,
                              maxLines: 3,
                              onChanged: (v) =>
                                  setState(() => _sandboxRawText = v),
                              decoration: InputDecoration(
                                hintText:
                                    'OCR-Zeile oder Log einfügen, z. B.:\nKlasse!\nZr-rrokex wrde aefar«t!',
                                isDense: true,
                                filled: true,
                                fillColor: isDark
                                    ? const Color(0xFF141522)
                                    : Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              key: const Key('sandbox_result_card'),
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF141522)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: eval.matches.isNotEmpty
                                      ? Colors.greenAccent.withValues(alpha: 0.4)
                                      : borderColor,
                                ),
                              ),
                              child: _buildSandboxEvaluationContent(eval),
                            ),
                          ] else ...[
                            _buildPhotoSandbox(isDark: isDark, borderColor: borderColor),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // CARD 3: Active Pattern Cards
                    _buildCard(
                      cardBg: cardBg,
                      borderColor: borderColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AKTIVE MUSTER (${_patterns.length})',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_patterns.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Noch keine eigenen Muster definiert.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          else
                            Column(
                              children: List.generate(_patterns.length, (index) {
                                final pat = _patterns[index];
                                return _buildPatternCardRow(
                                  pat: pat,
                                  index: index,
                                  isDark: isDark,
                                  borderColor: borderColor,
                                );
                              }),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Divider(height: 1, color: borderColor),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Schließen'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required Color cardBg,
    required Color borderColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }

  Widget _buildTypeSegmentPill({
    required Key key,
    required ScannerEventType type,
    required String label,
    required Color color,
  }) {
    final selected = _selectedType == type;
    return ChoiceChip(
      key: key,
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: selected,
      selectedColor: color.withValues(alpha: 0.22),
      visualDensity: VisualDensity.compact,
      onSelected: (_) => setState(() => _selectedType = type),
    );
  }

  Widget _buildQuickPresetChip({
    required Key key,
    required String template,
    required ScannerEventType eventType,
  }) {
    final norm = template.trim().toLowerCase();
    final alreadyExists = _patterns.any(
      (p) => p.template.trim().toLowerCase() == norm && p.eventType == eventType,
    );
    return ActionChip(
      key: key,
      avatar: Icon(
        alreadyExists ? Icons.check_circle_rounded : Icons.add_rounded,
        size: 14,
        color: alreadyExists ? Colors.greenAccent : null,
      ),
      label: Text(template, style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
      onPressed: () {
        setState(() => _selectedType = eventType);
        _addPattern(template, eventType);
      },
    );
  }

  Widget _buildSandboxTabPill({
    required Key key,
    required int index,
    required IconData icon,
    required String label,
  }) {
    final selected = _sandboxTabIndex == index;
    return ChoiceChip(
      key: key,
      avatar: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: selected,
      visualDensity: VisualDensity.compact,
      onSelected: (_) => setState(() => _sandboxTabIndex = index),
    );
  }

  Widget _buildSandboxEvaluationContent(
    ({
      OcrParseResult? parsed,
      List<FuzzyMatchResult> matches,
      bool isSmart,
    }) eval,
  ) {
    if (_sandboxRawText.trim().isEmpty) {
      return const Text(
        'Gib oben eine OCR-Zeile ein, um Muster + Smart-Search live zu prüfen.',
        style: TextStyle(fontSize: 11, color: Colors.grey),
      );
    }
    if (eval.parsed == null) {
      return const Text(
        'Kein Ereignis erkannt (UI/Rauschen oder fehlendes Muster).',
        style: TextStyle(fontSize: 11, color: Colors.amber),
      );
    }
    if (eval.matches.isEmpty) {
      return Text(
        'Typ: ${eval.parsed!.type.name} | Rohtext "${eval.parsed!.extractedPokemonName}" -> kein Pokédex-Treffer >= 72%',
        style: const TextStyle(fontSize: 11, color: Colors.orangeAccent),
      );
    }

    final best = eval.matches.first;
    final pct = (best.confidence * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                eval.parsed!.type.name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent,
                ),
              ),
            ),
            if (eval.isSmart)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.lightBlueAccent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'SMART-SEARCH',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.lightBlueAccent,
                  ),
                ),
              ),
            Text(
              '${best.canonicalName} (#${best.pokemonId}) · $pct%',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        if (eval.matches.length > 1) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: eval.matches.map((m) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${m.canonicalName} ${(m.confidence * 100).round()}%',
                  style: const TextStyle(fontSize: 10),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildPhotoSandbox({
    required bool isDark,
    required Color borderColor,
  }) {
    final frame = _sandboxFrame;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              key: const Key('btn_sandbox_load_photo'),
              onPressed: _pickPhotoFrame,
              icon: const Icon(Icons.photo_library_outlined, size: 15),
              label: const Text('Foto/Screenshot laden',
                  style: TextStyle(fontSize: 11)),
            ),
            if (widget.latestLiveFrame != null)
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _sandboxFrame = widget.latestLiveFrame;
                    _photoResults = const {};
                    _photoError = null;
                  });
                },
                icon: const Icon(Icons.desktop_windows_outlined, size: 15),
                label: const Text('Aktuellen Live-Frame nutzen',
                    style: TextStyle(fontSize: 11)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (frame == null)
          const Text(
            'Noch kein Frame geladen. Lade ein Emulator-/Kamera-Bild zum Testen.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          )
        else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141522) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Geladener Frame: ${frame.width}×${frame.height} (${frame.pixelFormat})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: OcrPreprocessProfile.values.map((p) {
                    return ChoiceChip(
                      label: Text(p.labelDe, style: const TextStyle(fontSize: 11)),
                      selected: _sandboxProfile == p,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => setState(() => _sandboxProfile = p),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    ElevatedButton.icon(
                      key: const Key('btn_sandbox_run_photo_ocr'),
                      onPressed:
                          (_runningPhotoOcr || widget.onRunPhotoOcr == null)
                              ? null
                              : () => _runPhotoOcr(compareAll: false),
                      icon: _runningPhotoOcr
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.document_scanner_outlined,
                              size: 15),
                      label: const Text('Foto mit OCR testen',
                          style: TextStyle(fontSize: 11)),
                    ),
                    OutlinedButton.icon(
                      onPressed:
                          (_runningPhotoOcr || widget.onRunPhotoOcr == null)
                              ? null
                              : () => _runPhotoOcr(compareAll: true),
                      icon: const Icon(Icons.compare_arrows_rounded, size: 15),
                      label: const Text('Alle 3 Profile vergleichen',
                          style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        if (_photoError != null) ...[
          const SizedBox(height: 6),
          Text(
            _photoError!,
            style: const TextStyle(fontSize: 11, color: Colors.redAccent),
          ),
        ],
        if (_photoResults.isNotEmpty) ...[
          const SizedBox(height: 8),
          ..._photoResults.entries.map((entry) {
            final joined = entry.value.lines.join(' | ');
            final eval = _evaluateSandboxText(entry.value.lines.join('\n'));
            final best = eval.matches.firstOrNull;
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141522) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.key.labelDe} (${entry.value.ocrDurationMs}ms)'
                    '${best != null ? ' -> ${best.canonicalName} (${(best.confidence * 100).round()}%)' : ''}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    joined.isEmpty ? '<kein Text erkannt>' : joined,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildPatternCardRow({
    required CustomOcrPattern pat,
    required int index,
    required bool isDark,
    required Color borderColor,
  }) {
    final (badgeLabel, badgeColor) = switch (pat.eventType) {
      ScannerEventType.caught => ('GEFANGEN', Colors.greenAccent),
      ScannerEventType.encounter => ('BEGEGNUNG', Colors.amberAccent),
      ScannerEventType.evolved => ('ENTWICKLUNG', Colors.lightBlueAccent),
      _ => (pat.eventType.name.toUpperCase(), Colors.grey),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141522) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeLabel,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: badgeColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pat.template,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Switch(
            value: pat.enabled,
            onChanged: (v) {
              setState(() {
                _patterns[index] = pat.copyWith(enabled: v);
              });
              _commitPatterns();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            onPressed: () {
              setState(() {
                _patterns.removeAt(index);
              });
              _commitPatterns();
            },
          ),
        ],
      ),
    );
  }
}
