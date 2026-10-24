import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_translations.dart';
import '../../providers/tutorial_provider.dart';

/// A dedicated screen presenting an overview of all mouse, keyboard, and touch controls.
///
/// Automatically adapts to the current operating platform (Desktop/Web vs. Mobile),
/// while allowing the user to seamlessly toggle between "Desktop & Web" and "Touch & Mobil".
class ControlsGuideScreen extends StatefulWidget {
  /// Optional target platform override, primarily useful for widget testing.
  final TargetPlatform? initialPlatform;

  const ControlsGuideScreen({super.key, this.initialPlatform});

  @override
  State<ControlsGuideScreen> createState() => _ControlsGuideScreenState();
}

class _ControlsGuideScreenState extends State<ControlsGuideScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final bool isDesktop = _resolveIsDesktop();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: isDesktop ? 0 : 1,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        Provider.of<TutorialProvider>(context, listen: false)
            .markFeatureAsSeen('controls_guide');
      } catch (_) {}
    });
  }

  bool _resolveIsDesktop() {
    if (widget.initialPlatform != null) {
      return widget.initialPlatform == TargetPlatform.windows ||
          widget.initialPlatform == TargetPlatform.macOS ||
          widget.initialPlatform == TargetPlatform.linux;
    }
    // If target platform is mobile OS (including browsers on mobile devices), default to Touch tab
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.fuchsia) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          Translator.get(
            'controls_guide_title',
            fallback: 'Bedienung & Tastaturkürzel',
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          tabs: [
            Tab(
              icon: const Icon(Icons.computer),
              text: Translator.get(
                'controls_tab_desktop',
                fallback: 'Desktop & Web',
              ),
            ),
            Tab(
              icon: const Icon(Icons.touch_app),
              text: Translator.get(
                'controls_tab_mobile',
                fallback: 'Touch & Mobil',
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _DesktopControlsTab(),
          _MobileControlsTab(),
        ],
      ),
    );
  }
}

class _DesktopControlsTab extends StatelessWidget {
  const _DesktopControlsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _PlatformInfoCard(
          icon: Icons.mouse_outlined,
          message: Translator.get(
            'controls_platform_hint_desktop',
            fallback:
                'Übersicht über alle Tastatur- und Mauskürzel für Desktop und Web.',
          ),
        ),
        const SizedBox(height: 16),
        _ControlCategorySection(
          icon: Icons.navigation_outlined,
          title: Translator.get(
            'controls_cat_general',
            fallback: 'Allgemein & Navigation',
          ),
          items: [
            _ControlItem(
              inputLabel: Translator.get(
                'controls_nav_back_key',
                fallback: 'Backspace / Browser Back',
              ),
              title: Translator.get(
                'back',
                fallback: 'Zurück',
              ),
              description: Translator.get(
                'controls_nav_back_desc',
                fallback:
                    'Zur vorherigen Ansicht zurückkehren oder Ordner schließen',
              ),
            ),
            _ControlItem(
              inputLabel: Translator.get(
                'controls_folder_nav',
                fallback: 'Klick / Tippen auf Ordner',
              ),
              title: Translator.get(
                'folder',
                fallback: 'Ordnernavigation',
              ),
              description: Translator.get(
                'controls_folder_nav_desc',
                fallback: 'Ordner öffnen oder im Ordner navigieren',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ControlCategorySection(
          icon: Icons.grid_view_rounded,
          title: Translator.get(
            'controls_cat_dex',
            fallback: 'Pokédex (PC-Box & Liste)',
          ),
          items: [
            _ControlItem(
              inputLabel: Translator.get(
                'controls_dex_toggle_click',
                fallback: 'Linksklick',
              ),
              title: Translator.get(
                'caught',
                fallback: 'Gefangen toggeln',
              ),
              description: Translator.get(
                'controls_dex_toggle_desc',
                fallback:
                    'Status Gefangen/Fehlt umschalten oder leeren Platzhalter belegen',
              ),
            ),
            _ControlItem(
              inputLabel: Translator.get(
                'controls_dex_details_click',
                fallback: 'Rechtsklick',
              ),
              title: Translator.get(
                'details',
                fallback: 'Pokémon-Details',
              ),
              description: Translator.get(
                'controls_dex_details_desc',
                fallback: 'Detail- und Informationsseite des Pokémon öffnen',
              ),
            ),
            _ControlItem(
              inputLabel: Translator.get(
                'controls_dex_details_key',
                fallback: 'Taste I / Strg + Enter',
              ),
              title: Translator.get(
                'details',
                fallback: 'Pokémon-Details (Tastatur)',
              ),
              description: Translator.get(
                'controls_dex_details_key_desc',
                fallback: 'Pokémon-Details bei Tastaturfokus öffnen',
              ),
            ),
            _ControlItem(
              inputLabel: Translator.get(
                'controls_dex_drag_desktop',
                fallback: 'Maus Drag & Drop',
              ),
              title: Translator.get(
                'move_pokemon',
                fallback: 'Verschieben & Tauschen',
              ),
              description: Translator.get(
                'controls_dex_drag_desc',
                fallback:
                    'Pokémon innerhalb oder zwischen Boxen verschieben / tauschen',
              ),
            ),
            _ControlItem(
              inputLabel: Translator.get(
                'controls_dex_multiselect',
                fallback: 'Mehrfachauswahl (Edit-Modus)',
              ),
              title: Translator.get(
                'edit',
                fallback: 'Bearbeiten-Modus',
              ),
              description: Translator.get(
                'controls_dex_multiselect_desc',
                fallback:
                    'Tippen im Bearbeiten-Modus, um mehrere Pokémon zu markieren',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ControlCategorySection(
          icon: Icons.home_rounded,
          title: Translator.get(
            'controls_cat_home',
            fallback: 'Hauptmenü (Home Screen)',
          ),
          items: [
            _ControlItem(
              inputLabel: Translator.get(
                'controls_home_reorder',
                fallback: 'Reorder-Handle (Ziehen)',
              ),
              title: Translator.get(
                'sort',
                fallback: 'Manuelle Sortierung',
              ),
              description: Translator.get(
                'controls_home_reorder_desc',
                fallback:
                    'Dexe und Ordner bei manueller Sortierung frei anordnen',
              ),
            ),
            _ControlItem(
              inputLabel: Translator.get(
                'controls_home_multiselect',
                fallback: 'Langer Druck (Longpress)',
              ),
              title: Translator.get(
                'selected',
                fallback: 'Auswahlmodus',
              ),
              description: Translator.get(
                'controls_home_multiselect_desc',
                fallback:
                    'Auswahlmodus aktivieren (Mehrfachauswahl für Verschieben & Löschen)',
              ),
            ),
            _ControlItem(
              inputLabel: Translator.get(
                'controls_home_menu',
                fallback: 'Dreipunkt-Menü (⋮)',
              ),
              title: Translator.get(
                'actions',
                fallback: 'Schnellaktionen',
              ),
              description: Translator.get(
                'controls_home_menu_desc',
                fallback:
                    'Schnellmenü für Umbenennen, Verschieben, Exportieren & Löschen',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ControlCategorySection(
          icon: Icons.auto_awesome,
          title: Translator.get(
            'controls_cat_shiny_hunt',
            fallback: 'Shiny Hunt Counter',
          ),
          items: [
            _ControlItem(
              inputLabel: Translator.get(
                'controls_hunt_inc_key',
                fallback: 'Leertaste / Pfeil Oben (↑)',
              ),
              title: Translator.get(
                'controls_hunt_inc_title',
                fallback: '+1 Encounter',
              ),
              description: Translator.get(
                'controls_hunt_inc_desc',
                fallback: 'Zähler um 1 (oder eingestellte Schrittweite) erhöhen',
              ),
            ),
            _ControlItem(
              inputLabel: Translator.get(
                'controls_hunt_dec_key',
                fallback: 'Pfeil Unten (↓) / Minus (-)',
              ),
              title: Translator.get(
                'controls_hunt_dec_title',
                fallback: '-1 Encounter',
              ),
              description: Translator.get(
                'controls_hunt_dec_desc',
                fallback: 'Zähler um 1 verringern (Fehlzählung korrigieren)',
              ),
            ),
            _ControlItem(
              inputLabel: Translator.get(
                'controls_hunt_pause_key',
                fallback: 'Taste P',
              ),
              title: Translator.get(
                'controls_hunt_pause_title',
                fallback: 'Pause / Resume',
              ),
              description: Translator.get(
                'controls_hunt_pause_desc',
                fallback: 'Jagd-Timer pausieren oder fortsetzen',
              ),
            ),
            _ControlItem(
              inputLabel: Translator.get(
                'controls_hunt_lock',
                fallback: 'Schloss-Symbol (Tap-Only)',
              ),
              title: Translator.get(
                'lock',
                fallback: 'Fehlklickschutz',
              ),
              description: Translator.get(
                'controls_hunt_lock_desc',
                fallback:
                    'Fehlklickschutz: Sperrt Tasten und verhindert versehentliche Zählungen',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ControlCategorySection(
          icon: Icons.military_tech_rounded,
          title: Translator.get(
            'controls_cat_ribbons_marks',
            fallback: 'Bänder & Zeichen',
          ),
          items: [
            _ControlItem(
              inputLabel: Translator.get(
                'controls_ribbon_toggle_click',
                fallback: 'Linksklick / Antippen',
              ),
              title: Translator.get(
                'status',
                fallback: 'Status ändern',
              ),
              description: Translator.get(
                'controls_ribbon_toggle_desc',
                fallback:
                    'Band oder Zeichen als erhalten oder nicht erhalten markieren',
              ),
            ),
            _ControlItem(
              inputLabel: Translator.get(
                'controls_ribbon_details_click',
                fallback: 'Rechtsklick / Langer Druck',
              ),
              title: Translator.get(
                'details',
                fallback: 'Detail-Informationen',
              ),
              description: Translator.get(
                'controls_ribbon_details_desc',
                fallback:
                    'Detailinformationen, Beschreibung und Fundort anzeigen',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ControlCategorySection(
          icon: Icons.flash_on_rounded,
          title: Translator.get(
            'controls_cat_abilities_moves',
            fallback: 'Fähigkeiten & Attacken',
          ),
          items: [
            _ControlItem(
              inputLabel: Translator.get(
                'controls_ability_toggle_click',
                fallback: 'Linksklick / Antippen',
              ),
              title: Translator.get(
                'status',
                fallback: 'Status toggeln',
              ),
              description: Translator.get(
                'controls_ability_toggle_desc',
                fallback: 'Status (z. B. Beherrscht / Gesehen) umschalten',
              ),
            ),
            _ControlItem(
              inputLabel: Translator.get(
                'controls_ability_details_click',
                fallback: 'Rechtsklick / Langer Druck',
              ),
              title: Translator.get(
                'details',
                fallback: 'Detailansicht',
              ),
              description: Translator.get(
                'controls_ability_details_desc',
                fallback: 'Detailansicht der Fähigkeit oder Attacke öffnen',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MobileControlsTab extends StatelessWidget {
  const _MobileControlsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _PlatformInfoCard(
          icon: Icons.touch_app_outlined,
          message: Translator.get(
            'controls_platform_hint_mobile',
            fallback:
                'Übersicht über alle Touch-, Wisch- und Longpress-Gesten für Mobilgeräte.',
          ),
        ),
        const SizedBox(height: 16),
        _ControlCategorySection(
          icon: Icons.navigation_outlined,
          title: Translator.get(
            'controls_cat_general',
            fallback: 'Allgemein & Navigation',
          ),
          items: [
            _ControlItem(
              inputLabel: Translator.get(
                'controls_nav_back_gesture',
                fallback: 'System-Zurück-Geste',
              ),
              title: Translator.get(
                'back',
                fallback: 'Zurück',
              ),
              description: Translator.get(
                'controls_nav_back_gesture_desc',
                fallback:
                    'Vom Bildschirmrand wischen oder Android-Zurücktaste',
              ),
            ),
            _ControlItem(
              inputLabel: Translator.get(
                'controls_folder_nav',
                fallback: 'Klick / Tippen auf Ordner',
              ),
              title: Translator.get(
                'folder',
                fallback: 'Ordnernavigation',
              ),
              description: Translator.get(
                'controls_folder_nav_desc',
                fallback: 'Ordner öffnen oder im Ordner navigieren',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ControlCategorySection(
          icon: Icons.grid_view_rounded,
          title: Translator.get(
            'controls_cat_dex',
            fallback: 'Pokédex (PC-Box & Liste)',
          ),
          items: [
            _ControlItem(
              inputLabel: Translator.get(
                'controls_dex_toggle_tap',
                fallback: 'Einfaches Antippen',
              ),
              title: Translator.get(
                'caught',
                fallback: 'Gefangen toggeln',
              ),
              description: Translator.get(
                'controls_dex_toggle_desc',
                fallback:
                    'Status Gefangen/Fehlt umschalten oder leeren Platzhalter belegen',
              ),
            ),
            _ControlItem(
              inputLabel: Translator.get(
                'controls_dex_details_longpress',
                fallback: 'Langer Druck (Longpress)',
              ),
              title: Translator.get(
                'details',
                fallback: 'Pokémon-Details',
              ),
              description: Translator.get(
                'controls_dex_details_desc',
                fallback: 'Detail- und Informationsseite des Pokémon öffnen',
              ),
            ),
            _ControlItem(
              inputLabel: Translator.get(
                'controls_dex_drag_mobile',
                fallback: 'Langer Druck + Ziehen',
              ),
              title: Translator.get(
                'move_pokemon',
                fallback: 'Verschieben & Tauschen',
              ),
              description: Translator.get(
                'controls_dex_drag_desc',
                fallback:
                    'Pokémon innerhalb oder zwischen Boxen verschieben / tauschen',
              ),
            ),
            _ControlItem(
              inputLabel: Translator.get(
                'controls_dex_multiselect',
                fallback: 'Mehrfachauswahl (Edit-Modus)',
              ),
              title: Translator.get(
                'edit',
                fallback: 'Bearbeiten-Modus',
              ),
              description: Translator.get(
                'controls_dex_multiselect_desc',
                fallback:
                    'Tippen im Bearbeiten-Modus, um mehrere Pokémon zu markieren',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ControlCategorySection(
          icon: Icons.home_rounded,
          title: Translator.get(
            'controls_cat_home',
            fallback: 'Hauptmenü (Home Screen)',
          ),
          items: [
            _ControlItem(
              inputLabel: Translator.get(
                'controls_home_multiselect',
                fallback: 'Langer Druck (Longpress)',
              ),
              title: Translator.get(
                'selected',
                fallback: 'Auswahlmodus',
              ),
              description: Translator.get(
                'controls_home_multiselect_desc',
                fallback:
                    'Auswahlmodus aktivieren (Mehrfachauswahl für Verschieben & Löschen)',
              ),
            ),
            _ControlItem(
              inputLabel: Translator.get(
                'controls_home_reorder',
                fallback: 'Reorder-Handle (Ziehen)',
              ),
              title: Translator.get(
                'sort',
                fallback: 'Manuelle Sortierung',
              ),
              description: Translator.get(
                'controls_home_reorder_desc',
                fallback:
                    'Dexe und Ordner bei manueller Sortierung frei anordnen',
              ),
            ),
            _ControlItem(
              inputLabel: Translator.get(
                'controls_home_menu',
                fallback: 'Dreipunkt-Menü (⋮)',
              ),
              title: Translator.get(
                'actions',
                fallback: 'Schnellaktionen',
              ),
              description: Translator.get(
                'controls_home_menu_desc',
                fallback:
                    'Schnellmenü für Umbenennen, Verschieben, Exportieren & Löschen',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ControlCategorySection(
          icon: Icons.auto_awesome,
          title: Translator.get(
            'controls_cat_shiny_hunt',
            fallback: 'Shiny Hunt Counter',
          ),
          items: [
            _ControlItem(
              inputLabel: Translator.get(
                'controls_hunt_inc_touch',
                fallback: 'Große Zählerfläche tippen',
              ),
              title: Translator.get(
                'controls_hunt_inc_title',
                fallback: '+1 Encounter',
              ),
              description: Translator.get(
                'controls_hunt_inc_desc',
                fallback: 'Zähler um 1 (oder eingestellte Schrittweite) erhöhen',
              ),
            ),
            _ControlItem(
              inputLabel: Translator.get(
                'controls_hunt_dec_touch',
                fallback: 'Minus-Button (-)',
              ),
              title: Translator.get(
                'controls_hunt_dec_title',
                fallback: '-1 Encounter',
              ),
              description: Translator.get(
                'controls_hunt_dec_desc',
                fallback: 'Zähler um 1 verringern (Fehlzählung korrigieren)',
              ),
            ),
            _ControlItem(
              inputLabel: Translator.get(
                'controls_hunt_pause_touch',
                fallback: 'Pause-Button (⏸)',
              ),
              title: Translator.get(
                'controls_hunt_pause_title',
                fallback: 'Pause / Resume',
              ),
              description: Translator.get(
                'controls_hunt_pause_desc',
                fallback: 'Jagd-Timer pausieren oder fortsetzen',
              ),
            ),
            _ControlItem(
              inputLabel: Translator.get(
                'controls_hunt_lock',
                fallback: 'Schloss-Symbol (Tap-Only)',
              ),
              title: Translator.get(
                'lock',
                fallback: 'Fehlklickschutz',
              ),
              description: Translator.get(
                'controls_hunt_lock_desc',
                fallback:
                    'Fehlklickschutz: Sperrt Tasten und verhindert versehentliche Zählungen',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ControlCategorySection(
          icon: Icons.military_tech_rounded,
          title: Translator.get(
            'controls_cat_ribbons_marks',
            fallback: 'Bänder & Zeichen',
          ),
          items: [
            _ControlItem(
              inputLabel: Translator.get(
                'controls_ribbon_toggle_click',
                fallback: 'Linksklick / Antippen',
              ),
              title: Translator.get(
                'status',
                fallback: 'Status ändern',
              ),
              description: Translator.get(
                'controls_ribbon_toggle_desc',
                fallback:
                    'Band oder Zeichen als erhalten oder nicht erhalten markieren',
              ),
            ),
            _ControlItem(
              inputLabel: Translator.get(
                'controls_ribbon_details_click',
                fallback: 'Rechtsklick / Langer Druck',
              ),
              title: Translator.get(
                'details',
                fallback: 'Detail-Informationen',
              ),
              description: Translator.get(
                'controls_ribbon_details_desc',
                fallback:
                    'Detailinformationen, Beschreibung und Fundort anzeigen',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ControlCategorySection(
          icon: Icons.flash_on_rounded,
          title: Translator.get(
            'controls_cat_abilities_moves',
            fallback: 'Fähigkeiten & Attacken',
          ),
          items: [
            _ControlItem(
              inputLabel: Translator.get(
                'controls_ability_toggle_click',
                fallback: 'Linksklick / Antippen',
              ),
              title: Translator.get(
                'status',
                fallback: 'Status toggeln',
              ),
              description: Translator.get(
                'controls_ability_toggle_desc',
                fallback: 'Status (z. B. Beherrscht / Gesehen) umschalten',
              ),
            ),
            _ControlItem(
              inputLabel: Translator.get(
                'controls_ability_details_click',
                fallback: 'Rechtsklick / Langer Druck',
              ),
              title: Translator.get(
                'details',
                fallback: 'Detailansicht',
              ),
              description: Translator.get(
                'controls_ability_details_desc',
                fallback: 'Detailansicht der Fähigkeit oder Attacke öffnen',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ControlItem {
  final String inputLabel;
  final String title;
  final String description;

  const _ControlItem({
    required this.inputLabel,
    required this.title,
    required this.description,
  });
}

class _PlatformInfoCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _PlatformInfoCard({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlCategorySection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<_ControlItem> items;

  const _ControlCategorySection({
    required this.icon,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return _ControlItemTile(item: item);
            },
          ),
        ),
      ],
    );
  }
}

class _ControlItemTile extends StatelessWidget {
  final _ControlItem item;

  const _ControlItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget buildBadge() {
      return Container(
        constraints: const BoxConstraints(minWidth: 90, maxWidth: 190),
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.35),
            width: 1.0,
          ),
        ),
        child: Text(
          item.inputLabel,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
            fontFamily: 'monospace',
          ),
        ),
      );
    }

    Widget buildText() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 380) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildBadge(),
                const SizedBox(height: 8),
                buildText(),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildBadge(),
              const SizedBox(width: 14),
              Expanded(child: buildText()),
            ],
          );
        },
      ),
    );
  }
}
