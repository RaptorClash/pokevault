import 'package:flutter/material.dart';

class BreadcrumbItem {
  final String id;
  final String title;

  BreadcrumbItem({required this.id, required this.title});
}

class BreadcrumbBar extends StatelessWidget {
  final List<BreadcrumbItem> path;
  final Function(String id) onFolderTap;
  final VoidCallback onHomeTap;

  const BreadcrumbBar({
    super.key,
    required this.path,
    required this.onFolderTap,
    required this.onHomeTap,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> breadcrumbWidgets = [];

    breadcrumbWidgets.add(
      InkWell(
        onTap: onHomeTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.home,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              const Text(
                'PokeVault',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );

    for (int i = 0; i < path.length; i++) {
      final folder = path[i];
      final isLast = i == path.length - 1;

      breadcrumbWidgets.add(
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Text('/', style: TextStyle(color: Colors.grey, fontSize: 18)),
        ),
      );

      breadcrumbWidgets.add(
        InkWell(
          onTap: isLast ? null : () => onFolderTap(folder.id),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
            child: Text(
              folder.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                color: isLast
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color,
              ),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection:
          Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: breadcrumbWidgets,
      ),
    );
  }
}
