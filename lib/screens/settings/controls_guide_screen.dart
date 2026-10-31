import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../i18n/strings.g.dart';
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
          t.controls_guide_title,
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          tabs: [
            Tab(
              icon: const Icon(Icons.computer),
              text: t.controls_tab_desktop,
            ),
            Tab(
              icon: const Icon(Icons.touch_app),
              text: t.controls_tab_mobile,
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
          message: t.controls_platform_hint_desktop,
        ),
        const SizedBox(height: 16),
        _ControlCategorySection(
          icon: Icons.navigation_outlined,
          title: t.controls_cat_general,
          items: [
            _ControlItem(
              inputLabel: t.controls_nav_back_key,
              title: t.back,
              description: t.controls_nav_back_desc,
            ),
            _ControlItem(
              inputLabel: t.controls_folder_nav,
              title: t.folder,
              description: t.controls_folder_nav_desc,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ControlCategorySection(
          icon: Icons.grid_view_rounded,
          title: t.controls_cat_dex,
          items: [
            _ControlItem(
              inputLabel: t.controls_dex_toggle_click,
              title: t.caught,
              description: t.controls_dex_toggle_desc,
            ),
            _ControlItem(
              inputLabel: t.controls_dex_details_click,
              title: t.details,
              description: t.controls_dex_details_desc,
            ),
            _ControlItem(
              inputLabel: t.controls_dex_details_key,
              title: t.details,
              description: t.controls_dex_details_key_desc,
            ),
            _ControlItem(
              inputLabel: t.controls_dex_drag_desktop,
              title: t.move_pokemon,
              description: t.controls_dex_drag_desc,
            ),
            _ControlItem(
              inputLabel: t.controls_dex_multiselect,
              title: t.edit,
              description: t.controls_dex_multiselect_desc,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ControlCategorySection(
          icon: Icons.home_rounded,
          title: t.controls_cat_home,
          items: [
            _ControlItem(
              inputLabel: t.controls_home_reorder,
              title: t.sort,
              description: t.controls_home_reorder_desc,
            ),
            _ControlItem(
              inputLabel: t.controls_home_multiselect,
              title: t.selected,
              description: t.controls_home_multiselect_desc,
            ),
            _ControlItem(
              inputLabel: t.controls_home_menu,
              title: t.actions,
              description: t.controls_home_menu_desc,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ControlCategorySection(
          icon: Icons.auto_awesome,
          title: t.controls_cat_shiny_hunt,
          items: [
            _ControlItem(
              inputLabel: t.controls_hunt_inc_key,
              title: t.controls_hunt_inc_title,
              description: t.controls_hunt_inc_desc,
            ),
            _ControlItem(
              inputLabel: t.controls_hunt_dec_key,
              title: t.controls_hunt_dec_title,
              description: t.controls_hunt_dec_desc,
            ),
            _ControlItem(
              inputLabel: t.controls_hunt_pause_key,
              title: t.controls_hunt_pause_title,
              description: t.controls_hunt_pause_desc,
            ),
            _ControlItem(
              inputLabel: t.controls_hunt_lock,
              title: t.lock,
              description: t.controls_hunt_lock_desc,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ControlCategorySection(
          icon: Icons.military_tech_rounded,
          title: t.controls_cat_ribbons_marks,
          items: [
            _ControlItem(
              inputLabel: t.controls_ribbon_toggle_click,
              title: t.status,
              description: t.controls_ribbon_toggle_desc,
            ),
            _ControlItem(
              inputLabel: t.controls_ribbon_details_click,
              title: t.details,
              description: t.controls_ribbon_details_desc,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ControlCategorySection(
          icon: Icons.flash_on_rounded,
          title: t.controls_cat_abilities_moves,
          items: [
            _ControlItem(
              inputLabel: t.controls_ability_toggle_click,
              title: t.status,
              description: t.controls_ability_toggle_desc,
            ),
            _ControlItem(
              inputLabel: t.controls_ability_details_click,
              title: t.details,
              description: t.controls_ability_details_desc,
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
          message: t.controls_platform_hint_mobile,
        ),
        const SizedBox(height: 16),
        _ControlCategorySection(
          icon: Icons.navigation_outlined,
          title: t.controls_cat_general,
          items: [
            _ControlItem(
              inputLabel: t.controls_nav_back_gesture,
              title: t.back,
              description: t.controls_nav_back_gesture_desc,
            ),
            _ControlItem(
              inputLabel: t.controls_folder_nav,
              title: t.folder,
              description: t.controls_folder_nav_desc,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ControlCategorySection(
          icon: Icons.grid_view_rounded,
          title: t.controls_cat_dex,
          items: [
            _ControlItem(
              inputLabel: t.controls_dex_toggle_tap,
              title: t.caught,
              description: t.controls_dex_toggle_desc,
            ),
            _ControlItem(
              inputLabel: t.controls_dex_details_longpress,
              title: t.details,
              description: t.controls_dex_details_desc,
            ),
            _ControlItem(
              inputLabel: t.controls_dex_drag_mobile,
              title: t.move_pokemon,
              description: t.controls_dex_drag_desc,
            ),
            _ControlItem(
              inputLabel: t.controls_dex_multiselect,
              title: t.edit,
              description: t.controls_dex_multiselect_desc,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ControlCategorySection(
          icon: Icons.home_rounded,
          title: t.controls_cat_home,
          items: [
            _ControlItem(
              inputLabel: t.controls_home_multiselect,
              title: t.selected,
              description: t.controls_home_multiselect_desc,
            ),
            _ControlItem(
              inputLabel: t.controls_home_reorder,
              title: t.sort,
              description: t.controls_home_reorder_desc,
            ),
            _ControlItem(
              inputLabel: t.controls_home_menu,
              title: t.actions,
              description: t.controls_home_menu_desc,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ControlCategorySection(
          icon: Icons.auto_awesome,
          title: t.controls_cat_shiny_hunt,
          items: [
            _ControlItem(
              inputLabel: t.controls_hunt_inc_touch,
              title: t.controls_hunt_inc_title,
              description: t.controls_hunt_inc_desc,
            ),
            _ControlItem(
              inputLabel: t.controls_hunt_dec_touch,
              title: t.controls_hunt_dec_title,
              description: t.controls_hunt_dec_desc,
            ),
            _ControlItem(
              inputLabel: t.controls_hunt_pause_touch,
              title: t.controls_hunt_pause_title,
              description: t.controls_hunt_pause_desc,
            ),
            _ControlItem(
              inputLabel: t.controls_hunt_lock,
              title: t.lock,
              description: t.controls_hunt_lock_desc,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ControlCategorySection(
          icon: Icons.military_tech_rounded,
          title: t.controls_cat_ribbons_marks,
          items: [
            _ControlItem(
              inputLabel: t.controls_ribbon_toggle_click,
              title: t.status,
              description: t.controls_ribbon_toggle_desc,
            ),
            _ControlItem(
              inputLabel: t.controls_ribbon_details_click,
              title: t.details,
              description: t.controls_ribbon_details_desc,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ControlCategorySection(
          icon: Icons.flash_on_rounded,
          title: t.controls_cat_abilities_moves,
          items: [
            _ControlItem(
              inputLabel: t.controls_ability_toggle_click,
              title: t.status,
              description: t.controls_ability_toggle_desc,
            ),
            _ControlItem(
              inputLabel: t.controls_ability_details_click,
              title: t.details,
              description: t.controls_ability_details_desc,
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
