import 'package:flutter/material.dart';

enum RotomMood { happy, explaining, thinking, alert }

enum ContentAlign { top, bottom, left, right }

class TutorialStep {
  final String? id;
  final GlobalKey? targetKey;
  final String titleKey;
  final String textKey;
  final bool requireTargetTap;
  final VoidCallback? onTargetTap;
  final int preCalculateDelayMilliseconds;
  final int tapDelayMilliseconds;
  final bool hideNextButton;
  final bool Function(double)? checkScroll;
  final bool disableScroll;
  final bool showHighlight;
  final double scrollAlignment;
  final bool requireLongPress;
  final RotomMood rotomMood;

  TutorialStep({
    this.id,
    this.targetKey,
    required this.titleKey,
    required this.textKey,
    this.requireTargetTap = false,
    this.onTargetTap,
    this.preCalculateDelayMilliseconds = 0,
    this.tapDelayMilliseconds = 0,
    this.hideNextButton = false,
    this.checkScroll,
    this.disableScroll = false,
    this.showHighlight = true,
    this.scrollAlignment = 0.5,
    this.requireLongPress = false,
    this.rotomMood = RotomMood.explaining,
  });
}

class TutorialFeature {
  final String id;
  final String nameKey;
  final List<TutorialStep> steps;

  TutorialFeature({
    required this.id,
    required this.nameKey,
    required this.steps,
  });
}

/// Represents a modular chapter in the tutorial system.
class TutorialChapter {
  final String id;
  final String titleKey;
  final String descKey;
  final IconData icon;
  final int version;
  final List<String> requiredFeatureKeys;
  final int stepCount;
  final List<TutorialStep> demoSteps;

  const TutorialChapter({
    required this.id,
    required this.titleKey,
    required this.descKey,
    required this.icon,
    this.version = 1,
    required this.requiredFeatureKeys,
    required this.stepCount,
    this.demoSteps = const [],
  });

  bool get isNewInV16 => version == 2;
}

/// Central registry of all tutorial chapters and their interactive demo steps.
class TutorialChapters {
  static final List<TutorialChapter> all = [
    // 1. Home & Collection
    TutorialChapter(
      id: 'module_home',
      titleKey: 'tutorial_chapter_home_title',
      descKey: 'tutorial_chapter_home_desc',
      icon: Icons.home,
      version: 1,
      requiredFeatureKeys: const [
        'home_screen',
        'open_dex',
        'home_organize_part1',
        'home_organize_part2',
      ],
      stepCount: 4,
      demoSteps: [
        TutorialStep(
          titleKey: 'tutorial_home_intro_title',
          textKey: 'tutorial_home_intro_text',
          rotomMood: RotomMood.happy,
        ),
        TutorialStep(
          titleKey: 'tutorial_home_fab_title',
          textKey: 'tutorial_home_fab_text',
          rotomMood: RotomMood.explaining,
        ),
        TutorialStep(
          titleKey: 'tutorial_home_organize_title',
          textKey: 'tutorial_home_organize_text',
          rotomMood: RotomMood.explaining,
        ),
        TutorialStep(
          titleKey: 'tutorial_home_search_title',
          textKey: 'tutorial_home_search_text',
          rotomMood: RotomMood.thinking,
        ),
      ],
    ),

    // 2. Dex Creation
    TutorialChapter(
      id: 'module_create_dex',
      titleKey: 'tutorial_chapter_create_dex_title',
      descKey: 'tutorial_chapter_create_dex_desc',
      icon: Icons.add_circle_outline,
      version: 1,
      requiredFeatureKeys: const ['create_dex_sheet'],
      stepCount: 4,
      demoSteps: [
        TutorialStep(
          titleKey: 'tutorial_create_name_title',
          textKey: 'tutorial_create_name_text',
          rotomMood: RotomMood.explaining,
        ),
        TutorialStep(
          titleKey: 'tutorial_create_group_title',
          textKey: 'tutorial_create_group_text',
          rotomMood: RotomMood.explaining,
        ),
        TutorialStep(
          titleKey: 'tutorial_create_options_title',
          textKey: 'tutorial_create_options_text',
          rotomMood: RotomMood.thinking,
        ),
        TutorialStep(
          titleKey: 'tutorial_create_save_title',
          textKey: 'tutorial_create_save_text',
          rotomMood: RotomMood.happy,
        ),
      ],
    ),

    // 3. Pokédex & Catch List
    TutorialChapter(
      id: 'module_dex_screen',
      titleKey: 'tutorial_chapter_dex_screen_title',
      descKey: 'tutorial_chapter_dex_screen_desc',
      icon: Icons.menu_book_outlined,
      version: 1,
      requiredFeatureKeys: const ['dex_screen', 'ignored_pokemon'],
      stepCount: 4,
      demoSteps: [
        TutorialStep(
          titleKey: 'tutorial_dex_tap_catch_title',
          textKey: 'tutorial_dex_tap_catch_text',
          rotomMood: RotomMood.explaining,
        ),
        TutorialStep(
          titleKey: 'tutorial_dex_details_title',
          textKey: 'tutorial_dex_details_text',
          rotomMood: RotomMood.explaining,
        ),
        TutorialStep(
          titleKey: 'tutorial_dex_modes_title',
          textKey: 'tutorial_dex_modes_text',
          rotomMood: RotomMood.thinking,
        ),
        TutorialStep(
          titleKey: 'tutorial_dex_filter_title',
          textKey: 'tutorial_dex_filter_text',
          rotomMood: RotomMood.happy,
        ),
      ],
    ),

    // 4. Box-Management (v1.6)
    TutorialChapter(
      id: 'module_box_management',
      titleKey: 'tutorial_chapter_box_mgmt_title',
      descKey: 'tutorial_chapter_box_mgmt_desc',
      icon: Icons.inventory_2_outlined,
      version: 2,
      requiredFeatureKeys: const ['box_management', 'box_drag_shift'],
      stepCount: 5,
      demoSteps: [
        TutorialStep(
          titleKey: 'tutorial_box_custom_title',
          textKey: 'tutorial_box_custom_text',
          rotomMood: RotomMood.explaining,
        ),
        TutorialStep(
          titleKey: 'tutorial_box_batch_title',
          textKey: 'tutorial_box_batch_text',
          rotomMood: RotomMood.explaining,
        ),
        TutorialStep(
          titleKey: 'tutorial_box_drag_title',
          textKey: 'tutorial_box_drag_text',
          rotomMood: RotomMood.thinking,
        ),
        TutorialStep(
          titleKey: 'tutorial_box_shift_title',
          textKey: 'tutorial_box_shift_text',
          rotomMood: RotomMood.explaining,
        ),
        TutorialStep(
          titleKey: 'tutorial_box_limits_title',
          textKey: 'tutorial_box_limits_text',
          rotomMood: RotomMood.happy,
        ),
      ],
    ),

    // 5. Shiny Hunt Tracker (v1.6)
    TutorialChapter(
      id: 'module_shiny_hunt',
      titleKey: 'tutorial_chapter_shiny_hunt_title',
      descKey: 'tutorial_chapter_shiny_hunt_desc',
      icon: Icons.auto_awesome,
      version: 2,
      requiredFeatureKeys: const ['shiny_hunt_hub', 'shiny_hunt_counter'],
      stepCount: 5,
      demoSteps: [
        TutorialStep(
          titleKey: 'tutorial_shiny_hub_title',
          textKey: 'tutorial_shiny_hub_text',
          rotomMood: RotomMood.happy,
        ),
        TutorialStep(
          titleKey: 'tutorial_shiny_new_title',
          textKey: 'tutorial_shiny_new_text',
          rotomMood: RotomMood.explaining,
        ),
        TutorialStep(
          titleKey: 'tutorial_shiny_counter_title',
          textKey: 'tutorial_shiny_counter_text',
          rotomMood: RotomMood.explaining,
        ),
        TutorialStep(
          titleKey: 'tutorial_shiny_phases_title',
          textKey: 'tutorial_shiny_phases_text',
          rotomMood: RotomMood.thinking,
        ),
        TutorialStep(
          titleKey: 'tutorial_shiny_stats_title',
          textKey: 'tutorial_shiny_stats_text',
          rotomMood: RotomMood.happy,
        ),
      ],
    ),

    // 6. Statistiken & Share-Card (v1.6)
    TutorialChapter(
      id: 'module_stats_share',
      titleKey: 'tutorial_chapter_stats_share_title',
      descKey: 'tutorial_chapter_stats_share_desc',
      icon: Icons.bar_chart,
      version: 2,
      requiredFeatureKeys: const ['dex_statistics', 'completion_card'],
      stepCount: 4,
      demoSteps: [
        TutorialStep(
          titleKey: 'tutorial_stats_intro_title',
          textKey: 'tutorial_stats_intro_text',
          rotomMood: RotomMood.explaining,
        ),
        TutorialStep(
          titleKey: 'tutorial_stats_breakdown_title',
          textKey: 'tutorial_stats_breakdown_text',
          rotomMood: RotomMood.thinking,
        ),
        TutorialStep(
          titleKey: 'tutorial_share_card_title',
          textKey: 'tutorial_share_card_text',
          rotomMood: RotomMood.happy,
        ),
        TutorialStep(
          titleKey: 'tutorial_share_formats_title',
          textKey: 'tutorial_share_formats_text',
          rotomMood: RotomMood.explaining,
        ),
      ],
    ),

    // 7. Pokémon Details & Tools (v1.6)
    TutorialChapter(
      id: 'module_pokemon_info',
      titleKey: 'tutorial_chapter_pokemon_info_title',
      descKey: 'tutorial_chapter_pokemon_info_desc',
      icon: Icons.search,
      version: 2,
      requiredFeatureKeys: const [
        'pokemon_details',
        'gender_differences',
        'special_obtainable',
      ],
      stepCount: 5,
      demoSteps: [
        TutorialStep(
          titleKey: 'tutorial_info_gender_title',
          textKey: 'tutorial_info_gender_text',
          rotomMood: RotomMood.explaining,
        ),
        TutorialStep(
          titleKey: 'tutorial_info_obtainable_title',
          textKey: 'tutorial_info_obtainable_text',
          rotomMood: RotomMood.explaining,
        ),
        TutorialStep(
          titleKey: 'tutorial_info_breeding_title',
          textKey: 'tutorial_info_breeding_text',
          rotomMood: RotomMood.thinking,
        ),
        TutorialStep(
          titleKey: 'tutorial_info_catch_calc_title',
          textKey: 'tutorial_info_catch_calc_text',
          rotomMood: RotomMood.explaining,
        ),
        TutorialStep(
          titleKey: 'tutorial_info_direct_hunt_title',
          textKey: 'tutorial_info_direct_hunt_text',
          rotomMood: RotomMood.happy,
        ),
      ],
    ),

    // 8. Routen- & Fundort-Tracker (v1.6)
    TutorialChapter(
      id: 'module_route_tracker',
      titleKey: 'tutorial_chapter_route_tracker_title',
      descKey: 'tutorial_chapter_route_tracker_desc',
      icon: Icons.map_outlined,
      version: 2,
      requiredFeatureKeys: const ['route_tracker'],
      stepCount: 4,
      demoSteps: [
        TutorialStep(
          titleKey: 'tutorial_route_hub_title',
          textKey: 'tutorial_route_hub_text',
          rotomMood: RotomMood.explaining,
        ),
        TutorialStep(
          titleKey: 'tutorial_route_spawns_title',
          textKey: 'tutorial_route_spawns_text',
          rotomMood: RotomMood.explaining,
        ),
        TutorialStep(
          titleKey: 'tutorial_route_filters_title',
          textKey: 'tutorial_route_filters_text',
          rotomMood: RotomMood.thinking,
        ),
        TutorialStep(
          titleKey: 'tutorial_route_mastery_title',
          textKey: 'tutorial_route_mastery_text',
          rotomMood: RotomMood.happy,
        ),
      ],
    ),

    // 9. Steuerung & Shortcuts (v1.6)
    TutorialChapter(
      id: 'module_controls',
      titleKey: 'tutorial_chapter_controls_title',
      descKey: 'tutorial_chapter_controls_desc',
      icon: Icons.sports_esports_outlined,
      version: 2,
      requiredFeatureKeys: const ['controls_guide'],
      stepCount: 4,
      demoSteps: [
        TutorialStep(
          titleKey: 'tutorial_ctrl_desktop_title',
          textKey: 'tutorial_ctrl_desktop_text',
          rotomMood: RotomMood.explaining,
        ),
        TutorialStep(
          titleKey: 'tutorial_ctrl_shortcuts_title',
          textKey: 'tutorial_ctrl_shortcuts_text',
          rotomMood: RotomMood.thinking,
        ),
        TutorialStep(
          titleKey: 'tutorial_ctrl_gestures_title',
          textKey: 'tutorial_ctrl_gestures_text',
          rotomMood: RotomMood.explaining,
        ),
        TutorialStep(
          titleKey: 'tutorial_ctrl_gamepad_title',
          textKey: 'tutorial_ctrl_gamepad_text',
          rotomMood: RotomMood.happy,
        ),
      ],
    ),

    // 10. Cloud-Sync & Datensicherung
    TutorialChapter(
      id: 'module_backup_sync',
      titleKey: 'tutorial_chapter_backup_title',
      descKey: 'tutorial_chapter_backup_desc',
      icon: Icons.cloud_sync_outlined,
      version: 1,
      requiredFeatureKeys: const ['cloud_sync', 'data_backup'],
      stepCount: 4,
      demoSteps: [
        TutorialStep(
          titleKey: 'tutorial_backup_cloud_title',
          textKey: 'tutorial_backup_cloud_text',
          rotomMood: RotomMood.explaining,
        ),
        TutorialStep(
          titleKey: 'tutorial_backup_auto_title',
          textKey: 'tutorial_backup_auto_text',
          rotomMood: RotomMood.explaining,
        ),
        TutorialStep(
          titleKey: 'tutorial_backup_export_title',
          textKey: 'tutorial_backup_export_text',
          rotomMood: RotomMood.thinking,
        ),
        TutorialStep(
          titleKey: 'tutorial_backup_restore_title',
          textKey: 'tutorial_backup_restore_text',
          rotomMood: RotomMood.happy,
        ),
      ],
    ),
  ];
}
