import 'package:material_ui/material_ui.dart';
import '../../../models/pokemon.dart';
import '../../../services/scanner_core/models/scanner_event.dart';

/// Opens the event correction modal for a detected scanner event.
Future<void> showMobileEventCorrectionDialog({
  required BuildContext context,
  required ScannerEvent event,
  required List<Pokemon> allPokemon,
  required void Function(ScannerEvent updatedEvent) onEventUpdated,
}) async {
  var query = event.matchedName;
  var isShiny = event.isShiny;
  var isAlpha = event.isAlpha;
  var selectedType = event.type;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDlg) {
        final candidates = allPokemon
            .where(
              (p) =>
                  p.nameDe.toLowerCase().contains(query.toLowerCase()) ||
                  p.nameEn.toLowerCase().contains(query.toLowerCase()) ||
                  p.id.toString() == query.trim(),
            )
            .take(8)
            .toList();

        return AlertDialog(
          title: const Text('Ereignis korrigieren', style: TextStyle(fontSize: 16)),
          content: SizedBox(
            width: 340,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<ScannerEventType>(
                    segments: const [
                      ButtonSegment(
                        value: ScannerEventType.caught,
                        label: Text('Gefangen'),
                      ),
                      ButtonSegment(
                        value: ScannerEventType.encounter,
                        label: Text('Begegnung'),
                      ),
                    ],
                    selected: {
                      selectedType == ScannerEventType.caught
                          ? ScannerEventType.caught
                          : ScannerEventType.encounter,
                    },
                    onSelectionChanged: (s) =>
                        setDlg(() => selectedType = s.first),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      FilterChip(
                        label: const Text('✨ Shiny'),
                        selected: isShiny,
                        onSelected: (v) => setDlg(() => isShiny = v),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('🔥 Alpha'),
                        selected: isAlpha,
                        onSelected: (v) => setDlg(() => isAlpha = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Pokémon suchen',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setDlg(() => query = v),
                  ),
                  const SizedBox(height: 8),
                  ...candidates.map(
                    (p) => ListTile(
                      dense: true,
                      title: Text('${p.nameDe} (#${p.id})'),
                      onTap: () {
                        final updated = event.copyWith(
                          pokemonId: p.id,
                          matchedName: p.nameDe,
                          type: selectedType,
                          isShiny: isShiny,
                          isAlpha: isAlpha,
                        );
                        onEventUpdated(updated);
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Schließen'),
            ),
          ],
        );
      },
    ),
  );
}

/// Shows an informational dialog explaining ignored starter/team Pokémon filtering.
void showMobileStarterFilterDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Team- & Starter-Schutz'),
      content: const Text(
        'Ignorierte Pokémon (z. B. dein eigenes Starter-Pokémon aus "Los, Pikachu!") werden bei Kampfeintritten übersprungen, bis du sie hier wieder entfernst.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
