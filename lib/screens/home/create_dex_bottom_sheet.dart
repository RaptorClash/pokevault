import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/dex_groups_data.dart';
import '../../l10n/app_translations.dart';
import '../../providers/dex_provider.dart';
import '../../providers/tutorial_provider.dart';
import '../../models/tutorial_step.dart';
import '../../widgets/tutorial/tutorial_overlay.dart';
import '../../utils/notification_helper.dart';

class CreateDexBottomSheet extends StatefulWidget {
  final DexProvider provider;
  final String currentFolderId;

  const CreateDexBottomSheet({
    super.key,
    required this.provider,
    required this.currentFolderId,
  });

  @override
  State<CreateDexBottomSheet> createState() => _CreateDexBottomSheetState();
}

class _CreateDexBottomSheetState extends State<CreateDexBottomSheet> {
  final GlobalKey _groupListKey = GlobalKey();
  final GlobalKey _kalosKey = GlobalKey();
  final GlobalKey _dropdownKey = GlobalKey();
  final GlobalKey _fakeDropdownKey = GlobalKey();
  final GlobalKey _nationalKey = GlobalKey();
  final GlobalKey _shinyKey = GlobalKey();
  final GlobalKey _genderKey = GlobalKey();
  final GlobalKey _formsExpansionKey = GlobalKey();
  final GlobalKey _regionalKey = GlobalKey();
  final GlobalKey _megaKey = GlobalKey();
  final GlobalKey _gmaxKey = GlobalKey();
  final GlobalKey _otherKey = GlobalKey();
  final GlobalKey _saveKey = GlobalKey();
  final ExpansibleController _expansionController = ExpansibleController();
  final TextEditingController nameController = TextEditingController();

  late DexGroup selectedGroup;
  late String selectedSubDex;
  bool includeGenders = false;
  bool includeRegional = false;
  bool includeMega = false;
  bool includeGMax = false;
  bool includeOther = false;
  bool isShinyDex = false;
  bool _showFakeDropdown = false;
  late Map<String, bool> features;

  @override
  void initState() {
    super.initState();
    try {
      selectedGroup = DexGroupsData.groups.first;
      selectedSubDex = selectedGroup.dexKeys.first;
      features = DexGroupsData.getAvailableFeatures(selectedSubDex);
      nameController.text = Translator.get('region_$selectedSubDex');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) _showTutorialIfNeeded();
        });
      });
    } catch (e) {
      NotificationHelper.showError('${Translator.get('error')} $e');
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void _showTutorialIfNeeded() {
    try {
      final tutProvider = Provider.of<TutorialProvider>(context, listen: false);
      if (!tutProvider.hasSeenFeature('create_dex_sheet')) {
        TutorialOverlay.show(
          context,
          TutorialFeature(
            id: 'create_dex_sheet',
            nameKey: 'tutorial_feature_home',
            steps: [
              TutorialStep(
                targetKey: _groupListKey,
                titleKey: 'tutorial_create_step1_title',
                textKey: 'tutorial_create_step1_text',
                requireTargetTap: false,
                hideNextButton: true,
                showHighlight: true,
                checkScroll: (pixels) => pixels >= 500,
              ),
              TutorialStep(
                targetKey: _kalosKey,
                titleKey: 'tutorial_create_step2_title',
                textKey: 'tutorial_create_step2_text',
                requireTargetTap: true,
                disableScroll: true,
                scrollAlignment: 0.5,
                onTargetTap: () {
                  final kalosGroup = DexGroupsData.groups.firstWhere(
                    (g) => g.dexKeys.first.contains('kalos'),
                  );
                  _selectGroupAndDex(kalosGroup, kalosGroup.dexKeys.first);
                },
              ),
              TutorialStep(
                targetKey: _dropdownKey,
                titleKey: 'tutorial_create_step3_title',
                textKey: 'tutorial_create_step3_text',
                requireTargetTap: true,
                preCalculateDelayMilliseconds: 400,
                onTargetTap: () => setState(() => _showFakeDropdown = true),
              ),
              TutorialStep(
                targetKey: _fakeDropdownKey,
                titleKey: 'tutorial_create_step3_5_title',
                textKey: 'tutorial_create_step3_5_text',
                requireTargetTap: true,
                preCalculateDelayMilliseconds: 300,
                onTargetTap: () {
                  final tapPos = TutorialOverlay.lastTapPosition;
                  int tappedIndex = 0;
                  if (tapPos != null && selectedGroup.dexKeys.length > 1) {
                    final renderBox =
                        _fakeDropdownKey.currentContext?.findRenderObject()
                            as RenderBox?;
                    if (renderBox != null) {
                      final localPos = renderBox.globalToLocal(tapPos);
                      final itemHeight =
                          renderBox.size.height / selectedGroup.dexKeys.length;
                      tappedIndex = (localPos.dy / itemHeight).floor().clamp(
                        0,
                        selectedGroup.dexKeys.length - 1,
                      );
                    }
                  }
                  setState(() {
                    _showFakeDropdown = false;
                    if (selectedGroup.dexKeys.length > 1) {
                      _selectSubDex(selectedGroup.dexKeys[tappedIndex]);
                    }
                  });
                },
              ),
              TutorialStep(
                id: 'swipe_back_national',
                targetKey: _groupListKey,
                titleKey: 'tutorial_create_step4_title',
                textKey: 'tutorial_create_step4_text',
                requireTargetTap: false,
                hideNextButton: true,
                showHighlight: true,
                preCalculateDelayMilliseconds: 500,
                checkScroll: (pixels) => pixels <= 5,
              ),
              TutorialStep(
                targetKey: _nationalKey,
                titleKey: 'tutorial_create_step5_title',
                textKey: 'tutorial_create_step5_text',
                requireTargetTap: true,
                disableScroll: true,
                scrollAlignment: 0.0,
                preCalculateDelayMilliseconds: 300,
                onTargetTap: () {
                  final natGroup = DexGroupsData.groups.firstWhere(
                    (g) => g.dexKeys.first.contains('national'),
                  );
                  _selectGroupAndDex(natGroup, natGroup.dexKeys.first);
                },
              ),
              TutorialStep(
                targetKey: _shinyKey,
                titleKey: 'tutorial_create_step6_title',
                textKey: 'tutorial_create_step6_text',
                requireTargetTap: true,
                onTargetTap: () => setState(() => isShinyDex = true),
              ),
              TutorialStep(
                targetKey: _genderKey,
                titleKey: 'tutorial_create_step7_title',
                textKey: 'tutorial_create_step7_text',
                requireTargetTap: true,
                onTargetTap: () => setState(() => includeGenders = true),
              ),
              TutorialStep(
                targetKey: _formsExpansionKey,
                titleKey: 'tutorial_create_step8_title',
                textKey: 'tutorial_create_step8_text',
                requireTargetTap: true,
                onTargetTap: () {
                  if (!_expansionController.isExpanded) {
                    _expansionController.expand();
                  }
                },
              ),
              TutorialStep(
                targetKey: _regionalKey,
                titleKey: 'tutorial_create_step9_title',
                textKey: 'tutorial_create_step9_text',
                requireTargetTap: true,
                preCalculateDelayMilliseconds: 350,
                onTargetTap: () => setState(() => includeRegional = true),
              ),
              TutorialStep(
                targetKey: _megaKey,
                titleKey: 'tutorial_create_step10_title',
                textKey: 'tutorial_create_step10_text',
                requireTargetTap: true,
                onTargetTap: () => setState(() => includeMega = true),
              ),
              TutorialStep(
                targetKey: _gmaxKey,
                titleKey: 'tutorial_create_step11_title',
                textKey: 'tutorial_create_step11_text',
                requireTargetTap: true,
                onTargetTap: () => setState(() => includeGMax = true),
              ),
              TutorialStep(
                targetKey: _otherKey,
                titleKey: 'tutorial_create_step12_title',
                textKey: 'tutorial_create_step12_text',
                requireTargetTap: true,
                onTargetTap: () => setState(() => includeOther = true),
              ),
              TutorialStep(
                targetKey: _saveKey,
                titleKey: 'tutorial_create_step13_title',
                textKey: 'tutorial_create_step13_text',
                requireTargetTap: true,
                onTargetTap: () {
                  Future.delayed(const Duration(milliseconds: 350), () {
                    if (mounted) _createDex();
                  });
                },
              ),
            ],
          ),
          () => tutProvider.markFeatureAsSeen('create_dex_sheet'),
          initialIndex: tutProvider.getFeatureStep('create_dex_sheet'),
          onStepChanged: (step) =>
              tutProvider.updateFatureStep('create_dex_sheet', step),
        );
      }
    } catch (e) {
      NotificationHelper.showError('${Translator.get('error')} $e');
    }
  }

  void _selectGroupAndDex(DexGroup group, String subDex) {
    setState(() {
      selectedGroup = group;
      _selectSubDex(subDex);
    });
  }

  void _selectSubDex(String subDex) {
    selectedSubDex = subDex;
    nameController.text = Translator.get('region_$selectedSubDex');
    features = DexGroupsData.getAvailableFeatures(selectedSubDex);
    includeMega = selectedSubDex == 'mega_dex';
    includeOther = selectedSubDex == 'icognito_dex';

    if (!(features['regional'] ?? false)) includeRegional = false;
    if (!(features['mega'] ?? false) && selectedSubDex != 'mega_dex')
      includeMega = false;
    if (!(features['gmax'] ?? false)) includeGMax = false;
    if (!(features['other'] ?? false) && selectedSubDex != 'icognito_dex')
      includeOther = false;
  }

  void _createDex() {
    try {
      if (nameController.text.isNotEmpty) {
        widget.provider.createDex(
          nameController.text,
          selectedSubDex,
          includeGenders,
          includeRegional,
          includeMega,
          includeGMax,
          includeOther,
          isShinyDex,
          widget.currentFolderId,
        );
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      NotificationHelper.showError('${Translator.get('error')} $e');
    }
  }

  Widget _buildCollage(List<int> ids) {
    const String baseUrl =
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/';
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Image.network(
                  '$baseUrl${ids[0]}.png',
                  fit: BoxFit.contain,
                ),
              ),
              Expanded(
                child: Image.network(
                  '$baseUrl${ids[1]}.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Image.network(
                  '$baseUrl${ids[2]}.png',
                  fit: BoxFit.contain,
                ),
              ),
              Expanded(
                child: Image.network(
                  '$baseUrl${ids[3]}.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenerationSelector() {
    return SizedBox(
      height: 160,
      key: _groupListKey,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: DexGroupsData.groups.map((group) {
            final isSelected = selectedGroup == group;
            Key? itemKey;
            if (group.dexKeys.first.contains('national')) {
              itemKey = _nationalKey;
            } else if (group.dexKeys.first.contains('kalos')) {
              itemKey = _kalosKey;
            }

            return Padding(
              padding: const EdgeInsets.only(right: 12, bottom: 8),
              child: GestureDetector(
                key: itemKey,
                onTap: () => _selectGroupAndDex(group, group.dexKeys.first),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 140,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.red.withValues(alpha: 0.15)
                        : Theme.of(context).colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? Colors.red : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _buildCollage(group.displayPokemonIds),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.red
                                : Colors.black.withValues(alpha: 0.1),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(14),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            Translator.get(group.nameKey),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDexDropdown() {
    if (selectedGroup.dexKeys.length <= 1) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: _dropdownKey,
          initialValue: selectedSubDex,
          decoration: InputDecoration(
            labelText: Translator.get('exact_pokedex'),
            filled: true,
            fillColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          items: selectedGroup.dexKeys.map((key) {
            return DropdownMenuItem<String>(
              value: key,
              child: Text(
                Translator.get('region_$key') != 'region_$key'
                    ? Translator.get('region_$key')
                    : key,
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectSubDex(val));
          },
        ),
        if (_showFakeDropdown)
          Container(
            key: _fakeDropdownKey,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: selectedGroup.dexKeys.map((key) {
                final isSelected = key == selectedSubDex;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() {
                    _showFakeDropdown = false;
                    _selectSubDex(key);
                  }),
                  child: Container(
                    color: isSelected
                        ? Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.2)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Text(
                      Translator.get('region_$key') != 'region_$key'
                          ? Translator.get('region_$key')
                          : key,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSettingsToggles() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SwitchListTile(
            key: _shinyKey,
            title: Text(
              Translator.get('tutorial_create_step6_title') !=
                      'tutorial_create_step6_title'
                  ? Translator.get('tutorial_create_step6_title')
                  : 'Shiny Dex',
            ),
            secondary: const Icon(Icons.star, color: Colors.amber),
            value: isShinyDex,
            activeThumbColor: Colors.amber,
            onChanged: (val) => setState(() => isShinyDex = val),
          ),
          const Divider(height: 1),
          SwitchListTile(
            key: _genderKey,
            title: Text(
              Translator.get('tutorial_create_step7_title') !=
                      'tutorial_create_step7_title'
                  ? Translator.get('tutorial_create_step7_title')
                  : 'Geschlechter',
            ),
            secondary: const Icon(Icons.wc),
            value: includeGenders,
            activeThumbColor: Colors.red,
            onChanged: (val) => setState(() => includeGenders = val),
          ),
          const Divider(height: 1),
          ExpansionTile(
            key: _formsExpansionKey,
            controller: _expansionController,
            initiallyExpanded:
                includeMega || includeRegional || includeGMax || includeOther,
            leading: const Icon(Icons.auto_awesome),
            title: Text(Translator.get('include_forms')),
            children: [
              CheckboxListTile(
                key: _regionalKey,
                title: Text(Translator.get('form_regional')),
                value: includeRegional,
                activeColor: Colors.red,
                enabled: (features['regional'] ?? false),
                onChanged: (features['regional'] ?? false)
                    ? (val) => setState(() => includeRegional = val ?? false)
                    : null,
              ),
              CheckboxListTile(
                key: _megaKey,
                title: Text(Translator.get('form_mega')),
                value: includeMega,
                activeColor: Colors.red,
                enabled:
                    (features['mega'] ?? false) &&
                    selectedSubDex != 'mega_dex',
                onChanged:
                    (features['mega'] ?? false) && selectedSubDex != 'mega_dex'
                    ? (val) => setState(() => includeMega = val ?? false)
                    : null,
              ),
              CheckboxListTile(
                key: _gmaxKey,
                title: Text(Translator.get('form_gmax')),
                value: includeGMax,
                activeColor: Colors.red,
                enabled: (features['gmax'] ?? false),
                onChanged: (features['gmax'] ?? false)
                    ? (val) => setState(() => includeGMax = val ?? false)
                    : null,
              ),
              CheckboxListTile(
                key: _otherKey,
                title: Text(Translator.get('form_other')),
                value: includeOther,
                activeColor: Colors.red,
                enabled:
                    (features['other'] ?? false) &&
                    selectedSubDex != 'icognito_dex',
                onChanged:
                    (features['other'] ?? false) &&
                        selectedSubDex != 'icognito_dex'
                    ? (val) => setState(() => includeOther = val ?? false)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomPadding,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Translator.get('create_dex_title'),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              Translator.get('choose_generation'),
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 16),
            _buildGenerationSelector(),
            const SizedBox(height: 16),
            _buildDexDropdown(),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: Translator.get('create_dex_hint'),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.edit),
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsToggles(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                key: _saveKey,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _createDex,
                child: Text(
                  Translator.get('create_dex_btn'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
