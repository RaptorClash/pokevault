import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../i18n/strings.g.dart';
import '../../../providers/shiny_hunt_provider.dart';

/// Encapsulates the AppBar action buttons for [DexScreen].
/// Supports both Normal Mode and Edit Mode.
class DexAppBarActions extends StatelessWidget {
  final bool isEditMode;
  final int selectedCount;
  final bool isBoxView;
  final bool separateForms;

  final Key? statsActionKey;
  final Key? shareActionKey;
  final Key? boxContentActionKey;
  final Key? boxEditActionKey;
  final Key? routeTrackerActionKey;
  final Key? shinyHuntActionKey;
  final Key? sortMenuKey;

  final VoidCallback? onDeleteSelected;
  final VoidCallback? onAddPokemon;
  final VoidCallback? onCancelEditMode;
  final VoidCallback? onSaveEditMode;
  final VoidCallback? onToggleEditMode;
  final VoidCallback? onOpenStats;
  final VoidCallback? onShareCard;
  final VoidCallback? onOpenBoxSettings;
  final VoidCallback? onOpenRouteTracker;
  final VoidCallback? onOpenShinyHunts;
  final VoidCallback? onToggleView;
  final VoidCallback? onToggleSeparateForms;
  final VoidCallback? onOpenSortSettings;
  final VoidCallback? onOpenIgnoredList;
  final VoidCallback? onDeleteDex;

  const DexAppBarActions({
    super.key,
    required this.isEditMode,
    this.selectedCount = 0,
    this.isBoxView = false,
    this.separateForms = false,
    this.statsActionKey,
    this.shareActionKey,
    this.boxContentActionKey,
    this.boxEditActionKey,
    this.routeTrackerActionKey,
    this.shinyHuntActionKey,
    this.sortMenuKey,
    this.onDeleteSelected,
    this.onAddPokemon,
    this.onCancelEditMode,
    this.onSaveEditMode,
    this.onToggleEditMode,
    this.onOpenStats,
    this.onShareCard,
    this.onOpenBoxSettings,
    this.onOpenRouteTracker,
    this.onOpenShinyHunts,
    this.onToggleView,
    this.onToggleSeparateForms,
    this.onOpenSortSettings,
    this.onOpenIgnoredList,
    this.onDeleteDex,
  });

  @override
  Widget build(BuildContext context) {
    if (isEditMode) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedCount > 0)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: t.box_edit_remove_selected,
              onPressed: onDeleteSelected,
            ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: t.add_pokemon,
            onPressed: onAddPokemon,
          ),
          if (onCancelEditMode != null)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: t.cancel,
              onPressed: onCancelEditMode,
            ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: t.save,
            onPressed: onSaveEditMode,
          ),
        ],
      );
    }

    final isWideEnoughForShare = MediaQuery.sizeOf(context).width >= 360;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: statsActionKey ?? const Key('_statsActionKey'),
          icon: const Icon(Icons.bar_chart),
          tooltip: t.dex_progress_tooltip,
          onPressed: onOpenStats,
        ),
        if (isWideEnoughForShare && onShareCard != null)
          IconButton(
            key: shareActionKey ?? const Key('_shareActionKey'),
            icon: const Icon(Icons.share),
            tooltip: t.share_dex_card,
            onPressed: onShareCard,
          ),
        IconButton(
          key: boxContentActionKey ?? const Key('_boxContentActionKey'),
          icon: const Icon(Icons.checklist),
          tooltip: t.box_edit_manage_content,
          onPressed: onToggleEditMode,
        ),
        if (onOpenBoxSettings != null)
          IconButton(
            key: boxEditActionKey ?? const Key('_boxEditActionKey'),
            icon: const Icon(Icons.edit_note),
            tooltip: t.box_edit_title,
            onPressed: onOpenBoxSettings,
          ),
        if (onOpenRouteTracker != null)
          IconButton(
            key: routeTrackerActionKey ?? const Key('_routeTrackerActionKey'),
            icon: const Icon(Icons.location_on),
            tooltip: t.route_tracker,
            onPressed: onOpenRouteTracker,
          ),
        if (onOpenShinyHunts != null)
          Builder(
            builder: (context) {
              ShinyHuntProvider? huntProvider;
              try {
                huntProvider = Provider.of<ShinyHuntProvider>(context);
              } catch (_) {
                huntProvider = null;
              }
              final count = huntProvider?.activeHunts.length ?? 0;
              return IconButton(
                key: shinyHuntActionKey ?? const Key('_shinyHuntActionKey'),
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.auto_awesome),
                ),
                tooltip: t.shiny_hunt_badge_tooltip,
                onPressed: onOpenShinyHunts,
              );
            },
          ),
        PopupMenuButton<String>(
          key: sortMenuKey ?? const Key('_sortMenuKey'),
          icon: const Icon(Icons.sort),
          tooltip: t.tooltip_view_sort,
          onSelected: (value) {
            switch (value) {
              case 'toggle_view':
                onToggleView?.call();
                break;
              case 'toggle_sort':
                onToggleSeparateForms?.call();
                break;
              case 'advanced_sort':
                onOpenSortSettings?.call();
                break;
              case 'ignored_list':
                onOpenIgnoredList?.call();
                break;
              case 'share_card':
                onShareCard?.call();
                break;
              case 'delete_dex':
                onDeleteDex?.call();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'toggle_view',
              child: Row(
                children: [
                  Icon(
                    isBoxView ? Icons.list : Icons.grid_view,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isBoxView ? t.view_list : t.view_box,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle_sort',
              child: Row(
                children: [
                  Icon(
                    separateForms
                        ? Icons.format_list_numbered
                        : Icons.category,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      separateForms ? t.sort_dex : t.sort_forms,
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'advanced_sort',
              child: Row(
                children: [
                  const Icon(Icons.tune, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(t.advanced_sort_title),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'ignored_list',
              child: Row(
                children: [
                  const Icon(Icons.visibility_off, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(t.ignored_list_title),
                  ),
                ],
              ),
            ),
            if (onShareCard != null) ...[
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'share_card',
                child: Row(
                  children: [
                    const Icon(Icons.share, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(t.share_dex_card),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
