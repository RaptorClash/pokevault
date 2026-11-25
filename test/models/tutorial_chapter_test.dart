import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/tutorial_step.dart';

void main() {
  group('TutorialChapter Model Tests', () {
    test('TutorialChapter properties are initialized correctly', () {
      const chapter = TutorialChapter(
        id: 'module_box_management',
        titleKey: 'tutorial_chapter_box_mgmt_title',
        descKey: 'tutorial_chapter_box_mgmt_desc',
        icon: Icons.inventory_2_outlined,
        version: 2,
        requiredFeatureKeys: ['box_management', 'box_drag_shift'],
        stepCount: 5,
      );

      expect(chapter.id, equals('module_box_management'));
      expect(chapter.titleKey, equals('tutorial_chapter_box_mgmt_title'));
      expect(chapter.descKey, equals('tutorial_chapter_box_mgmt_desc'));
      expect(chapter.icon, equals(Icons.inventory_2_outlined));
      expect(chapter.version, equals(2));
      expect(chapter.isNewInV16, isTrue);
      expect(chapter.requiredFeatureKeys, contains('box_management'));
      expect(chapter.stepCount, equals(5));
    });

    test('isNewInV16 returns false for version 1 chapters', () {
      const chapter = TutorialChapter(
        id: 'module_home',
        titleKey: 'tutorial_chapter_home_title',
        descKey: 'tutorial_chapter_home_desc',
        icon: Icons.home,
        version: 1,
        requiredFeatureKeys: ['home_screen'],
        stepCount: 4,
      );

      expect(chapter.isNewInV16, isFalse);
    });

    test('TutorialChapters registry provides all core + platform scanner + v1.7 auto-counter chapters', () {
      final chapters = TutorialChapters.all;
      expect(chapters.length, equals(13));

      final ids = chapters.map((c) => c.id).toList();
      expect(ids, containsAll([
        'module_home',
        'module_create_dex',
        'module_dex_screen',
        'module_box_management',
        'module_shiny_hunt',
        'module_stats_share',
        'module_pokemon_info',
        'module_route_tracker',
        'module_controls',
        'module_backup_sync',
        'module_scanner_mobile',
        'module_scanner_desktop',
        'module_shiny_auto_counter',
      ]));

      // Verify v1.6 new chapters count (6 chapters: boxes, shiny, stats, info, route, controls)
      final v16Chapters = chapters.where((c) => c.isNewInV16).toList();
      expect(v16Chapters.length, equals(6));

      // Verify v1.7 new chapters (mobile scanner, desktop scanner, shiny auto-counter)
      final v17Chapters = chapters.where((c) => c.isNewInV17).toList();
      expect(v17Chapters.length, equals(3));

      final shinyCh = chapters.firstWhere((c) => c.id == 'module_shiny_hunt');
      expect(shinyCh.stepCount, equals(6));

      final autoCh = chapters.firstWhere((c) => c.id == 'module_shiny_auto_counter');
      expect(autoCh.version, equals(3));
      expect(autoCh.mobileOnly, isNull);
      expect(autoCh.stepCount, equals(5));
      expect(autoCh.requiredFeatureKeys, containsAll([
        'multi_hunt_dashboard',
        'shiny_auto_counter_setup',
        'shiny_auto_counter_bar',
      ]));

      // Each chapter must have demo steps defined
      for (final ch in chapters) {
        expect(ch.demoSteps, isNotEmpty);
        expect(ch.stepCount, equals(ch.demoSteps.length));
      }

      final backupCh = chapters.firstWhere((c) => c.id == 'module_backup_sync');
      expect(backupCh.titleKey, equals('tutorial_chapter_backup_title'));
      expect(backupCh.descKey, equals('tutorial_chapter_backup_desc'));
      expect(backupCh.icon, equals(Icons.cloud_sync_outlined));
      expect(backupCh.stepCount, equals(4));
      expect(backupCh.requiredFeatureKeys, containsAll(['cloud_sync', 'data_backup']));
    });

    test('TutorialStep rotomMood defaults to explaining', () {
      final step = TutorialStep(
        titleKey: 'test_title',
        textKey: 'test_text',
      );
      expect(step.rotomMood, equals(RotomMood.explaining));
    });

    test('TutorialStep accepts explicit rotomMood', () {
      final step = TutorialStep(
        titleKey: 'test_title',
        textKey: 'test_text',
        rotomMood: RotomMood.alert,
      );
      expect(step.rotomMood, equals(RotomMood.alert));
    });

    test('visibleForPlatform filters scanner chapters between mobile and desktop', () {
      final mobileChapters = TutorialChapters.visibleForPlatform(isMobile: true);
      final desktopChapters = TutorialChapters.visibleForPlatform(isMobile: false);

      expect(mobileChapters.any((c) => c.id == 'module_scanner_mobile'), isTrue);
      expect(mobileChapters.any((c) => c.id == 'module_scanner_desktop'), isFalse);

      expect(desktopChapters.any((c) => c.id == 'module_scanner_desktop'), isTrue);
      expect(desktopChapters.any((c) => c.id == 'module_scanner_mobile'), isFalse);

      final mobScanner = mobileChapters.firstWhere((c) => c.id == 'module_scanner_mobile');
      final deskScanner = desktopChapters.firstWhere((c) => c.id == 'module_scanner_desktop');
      expect(mobScanner.version, equals(3));
      expect(deskScanner.version, equals(3));
      expect(mobScanner.demoSteps.length, equals(mobScanner.stepCount));
      expect(deskScanner.demoSteps.length, equals(deskScanner.stepCount));
    });
  });
}
