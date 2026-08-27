import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_translations.dart';
import '../../../utils/shiny_logic_helper.dart';
import '../../../providers/dex_provider.dart';
import 'breeding_data.dart';
import 'pokemon_avatar.dart';

class BreedingStepCard extends StatelessWidget {
  final int stepNumber;
  final int parent1Id;
  final bool p1Shiny;
  final String p1Gender;
  final bool p1Carrier;
  final int parent2Id;
  final bool p2Shiny;
  final String p2Gender;
  final bool p2Carrier;
  final int childId;
  final bool cShiny;
  final String cGender;
  final bool cCarrier;
  final bool isFinal;
  final String? dittoHint;

  const BreedingStepCard({
    super.key,
    required this.stepNumber,
    required this.parent1Id,
    required this.p1Shiny,
    required this.p1Gender,
    required this.p1Carrier,
    required this.parent2Id,
    required this.p2Shiny,
    required this.p2Gender,
    required this.p2Carrier,
    required this.childId,
    required this.cShiny,
    required this.cGender,
    required this.cCarrier,
    required this.isFinal,
    this.dittoHint,
  });

  Widget _buildFamilyAvatarRow(
    BuildContext context,
    int id,
    bool isShiny,
    String gender, {
    bool isCarrier = false,
  }) {
    final provider = context.read<DexProvider>();
    List<int> family = BreedingData.getFullFamily(id, provider);
    if (family.length <= 1) {
      return PokemonAvatar(
        id: family.first,
        isShiny: isShiny,
        gender: gender,
        isCarrier: isCarrier,
      );
    }
    String oneOfText = Translator.currentLanguage == 'de'
        ? 'Eines davon:'
        : 'One of these:';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            oneOfText,
            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: family
                .map(
                  (fid) => PokemonAvatar(
                    id: fid,
                    isShiny: isShiny,
                    gender: gender,
                    isCarrier: isCarrier,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionUI(
    BuildContext context,
    int fromId,
    int toId,
    bool cShiny,
    String cGender,
    int childId,
    String req,
    bool isMobile,
    bool isCarrier,
  ) {
    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.upgrade,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  Translator.get('shiny_breed_evo_step'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PokemonAvatar(
              id: fromId,
              isShiny: cShiny,
              gender: cGender,
              sizeScale: 0.9,
              isCarrier: isCarrier,
            ),
            const SizedBox(height: 8),
            const Icon(
              Icons.arrow_downward_rounded,
              color: Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 8),
            PokemonAvatar(
              id: toId,
              isShiny: cShiny,
              gender: cGender,
              isHighlight: toId == childId,
              sizeScale: 0.9,
              isCarrier: isCarrier,
            ),
            const SizedBox(height: 8),
            Text(
              '($req)',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Icon(
              Icons.upgrade,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            Text(
              Translator.get('shiny_breed_evo_step'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            PokemonAvatar(
              id: fromId,
              isShiny: cShiny,
              gender: cGender,
              sizeScale: 0.9,
              isCarrier: isCarrier,
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.grey,
              size: 20,
            ),
            PokemonAvatar(
              id: toId,
              isShiny: cShiny,
              gender: cGender,
              isHighlight: toId == childId,
              sizeScale: 0.9,
              isCarrier: isCarrier,
            ),
            Text(
              '($req)',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DexProvider>();
    String stepText = Translator.currentLanguage == 'de' ? 'Schritt' : 'Step';
    int baseChildId = ShinyLogicHelper.getBaseForm(childId);
    bool needsEvolution =
        baseChildId != childId &&
        (isFinal || ShinyLogicHelper.isBaby(baseChildId));
    bool isMobile = MediaQuery.of(context).size.width < 600;

    var g1 =
        BreedingData.getEggGroups(provider)[ShinyLogicHelper.getBaseForm(
          parent1Id,
        )] ??
        [];
    var g2 =
        BreedingData.getEggGroups(provider)[ShinyLogicHelper.getBaseForm(
          parent2Id,
        )] ??
        [];
    String sharedGroup = g1.firstWhere(
      (g) => g2.contains(g),
      orElse: () => 'Unbekannt',
    );
    String transGroup = Translator.get(
      'region_egg_${sharedGroup.toLowerCase()}',
    );
    if (transGroup.startsWith('region_egg_')) transGroup = sharedGroup;

    final targetPoke = provider.allPokemon
        .where((p) => p.id == childId)
        .firstOrNull;
    String realOdds = cCarrier
        ? (Translator.get('chance_carrier') != 'chance_carrier'
              ? Translator.get('chance_carrier')
              : 'Chance: 1:2 (Gen-Trägerin)')
        : (targetPoke != null
              ? BreedingData.getRealOdds(targetPoke, cGender)
              : '1:128');

    Widget p1Widget = p1Shiny || p1Carrier
        ? PokemonAvatar(
            id: parent1Id,
            isShiny: p1Shiny,
            gender: p1Gender,
            isCarrier: p1Carrier,
          )
        : _buildFamilyAvatarRow(
            context,
            parent1Id,
            p1Shiny,
            p1Gender,
            isCarrier: p1Carrier,
          );

    Widget p2Widget = p2Shiny || p2Carrier
        ? PokemonAvatar(
            id: parent2Id,
            isShiny: p2Shiny,
            gender: p2Gender,
            isCarrier: p2Carrier,
          )
        : _buildFamilyAvatarRow(
            context,
            parent2Id,
            p2Shiny,
            p2Gender,
            isCarrier: p2Carrier,
          );

    Widget childWidget = PokemonAvatar(
      id: baseChildId,
      isShiny: cShiny,
      gender: cGender,
      isHighlight: !needsEvolution,
      isCarrier: cCarrier,
    );

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$stepText $stepNumber',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (sharedGroup != 'Unbekannt' && parent1Id != 132)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      transGroup,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
            if (dittoHint != null) ...[
              const SizedBox(height: 8),
              Text(
                dittoHint!,
                style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 16),
            isMobile
                ? Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        p1Widget,
                        const SizedBox(height: 12),
                        const Icon(Icons.add, color: Colors.grey, size: 24),
                        const SizedBox(height: 12),
                        p2Widget,
                        const SizedBox(height: 12),
                        const Icon(
                          Icons.arrow_downward_rounded,
                          color: Colors.grey,
                          size: 28,
                        ),
                        const SizedBox(height: 12),
                        childWidget,
                      ],
                    ),
                  )
                : Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        p1Widget,
                        const Icon(Icons.add, color: Colors.grey, size: 24),
                        p2Widget,
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.grey,
                          size: 32,
                        ),
                        childWidget,
                      ],
                    ),
                  ),
            if (needsEvolution) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              ...ShinyLogicHelper.getEvolutionPath(baseChildId, childId).map((
                step,
              ) {
                return _buildEvolutionUI(
                  context,
                  step['from'],
                  step['to'],
                  cShiny,
                  cGender,
                  childId,
                  Translator.get(step['req']),
                  isMobile,
                  cCarrier,
                );
              }),
            ],
            if (cCarrier)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          Translator.get('shiny_breed_carrier_note'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: cCarrier
                      ? Colors.blue.withValues(alpha: 0.15)
                      : (realOdds.contains('1:')
                            ? Colors.amber.withValues(alpha: 0.15)
                            : Colors.red.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cCarrier
                        ? Colors.blue
                        : (realOdds.contains('1:') ? Colors.amber : Colors.red),
                  ),
                ),
                child: Text(
                  isFinal && !cCarrier
                      ? '${Translator.get('shiny_breed_chance')}: $realOdds (${Translator.currentLanguage == 'de' ? 'Ziel erreicht!' : 'Goal reached!'})'
                      : (cCarrier
                            ? realOdds
                            : (realOdds.contains('1:')
                                  ? '${Translator.get('shiny_breed_chance')}: $realOdds'
                                  : realOdds)),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: cCarrier
                        ? Colors.blue
                        : (realOdds.contains('1:') ? Colors.amber : Colors.red),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
