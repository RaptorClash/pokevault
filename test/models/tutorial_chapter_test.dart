import 'package:flutter/material.dart';
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

    test('TutorialChapters registry provides all 10 core chapters', () {
      final chapters = TutorialChapters.all;
      expect(chapters.length, equals(10));

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
      ]));

      // Verify v1.6 new chapters count (6 chapters: boxes, shiny, stats, info, route, controls)
      final v16Chapters = chapters.where((c) => c.isNewInV16).toList();
      expect(v16Chapters.length, equals(6));

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
  });
}
