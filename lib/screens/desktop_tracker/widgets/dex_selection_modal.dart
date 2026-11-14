import 'package:flutter/material.dart';
import '../../../models/user_dex.dart';
import '../../../utils/dex_logic_helper.dart';

/// Modal dialog for browsing, filtering and selecting the active target Pokédex.
class DexSelectionModal extends StatefulWidget {
  final List<UserDex> userDexes;
  final String? selectedDexId;
  final ValueChanged<UserDex> onDexSelected;
  final VoidCallback? onClose;

  const DexSelectionModal({
    super.key,
    required this.userDexes,
    this.selectedDexId,
    required this.onDexSelected,
    this.onClose,
  });

  @override
  State<DexSelectionModal> createState() => _DexSelectionModalState();
}

class _DexSelectionModalState extends State<DexSelectionModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getInitials(String title) {
    final words = title.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (title.isNotEmpty) {
      return title.substring(0, title.length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'DX';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredDexes = widget.userDexes.where((dex) {
      if (_searchQuery.isEmpty) return true;
      final t = dex.title.toLowerCase();
      final r = dex.region.toLowerCase();
      return t.contains(_searchQuery) || r.contains(_searchQuery);
    }).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 520,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? const Color(0xFF2C2C3E) : Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.menu_book, color: Color(0xFFEF5350), size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Ziel-Pokédex auswählen',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Search Bar
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: TextField(
                key: const Key('input_search_dex'),
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Pokédex durchsuchen...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF161622) : Colors.grey.shade100,
                ),
              ),
            ),

            // Dex List
            Flexible(
              child: filteredDexes.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          'Kein passender Pokédex gefunden.',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black45,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      itemCount: filteredDexes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final dex = filteredDexes[index];
                        final isSelected = widget.selectedDexId == dex.id;
                        final stats = DexLogicHelper.computeDexProgress(dex);
                        final caughtCount = stats.caughtCount;
                        final totalCount = stats.totalCount;
                        final initials = _getInitials(dex.title);

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              widget.onDexSelected(dex);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark ? const Color(0xFF28283C) : Colors.red.shade50)
                                    : (isDark ? const Color(0xFF161622) : Colors.grey.shade50),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFEF5350)
                                      : (isDark ? const Color(0xFF2E2E40) : Colors.grey.shade200),
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Badge Initial
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isSelected
                                            ? const [Color(0xFFE53935), Color(0xFFC62828)]
                                            : const [Color(0xFF3949AB), Color(0xFF283593)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        initials,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // Title & Progress
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                dex.title,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: isDark ? Colors.white : Colors.black87,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            if (isSelected)
                                              const Text(
                                                'Aktiv ✔',
                                                style: TextStyle(
                                                  color: Color(0xFFEF5350),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$caughtCount von $totalCount gefangen • ${dex.region.toUpperCase()}',
                                          style: TextStyle(
                                            color: isDark ? Colors.white54 : Colors.black54,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
