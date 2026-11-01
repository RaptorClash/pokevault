import 'package:flutter/material.dart';
import '../../../i18n/strings.g.dart';

/// Modular search and filter bar for [DexScreen].
class DexFilterBar extends StatelessWidget {
  final Key? searchBarKey;
  final TextEditingController searchController;
  final FocusNode? searchFocusNode;
  final String searchQuery;
  final String filter;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onSearchHelp;
  final ValueChanged<String?> onFilterChanged;

  const DexFilterBar({
    super.key,
    this.searchBarKey,
    required this.searchController,
    this.searchFocusNode,
    required this.searchQuery,
    required this.filter,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onSearchHelp,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: searchBarKey,
              focusNode: searchFocusNode,
              controller: searchController,
              decoration: InputDecoration(
                hintText: t.search_hint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: onClearSearch,
                      ),
                    IconButton(
                      icon: const Icon(Icons.help_outline),
                      onPressed: onSearchHelp,
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: onSearchChanged,
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: filter,
            items: [
              DropdownMenuItem(
                value: 'all',
                child: Text(t.filter_all),
              ),
              DropdownMenuItem(
                value: 'caught',
                child: Text(t.filter_caught),
              ),
              DropdownMenuItem(
                value: 'uncaught',
                child: Text(t.filter_missing),
              ),
            ],
            onChanged: onFilterChanged,
          ),
        ],
      ),
    );
  }
}
