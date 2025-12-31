import 'package:flutter/material.dart';

class CategoryFilter extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final Function(String?) onCategorySelected;
  final Function(String) onDeleteCategory;

  const CategoryFilter({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onDeleteCategory,
  });

  void _showDeleteConfirmation(BuildContext context, String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "$category"?\n\nAll ratings in this category will also be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onDeleteCategory(category);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.filter_list,
        color: selectedCategory != null ? Theme.of(context).colorScheme.primary : null,
      ),
      tooltip: 'Filter by Category',
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (value) {
        if (value == 'All') {
          onCategorySelected(null);
        } else {
          onCategorySelected(value);
        }
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[
          PopupMenuItem(
            value: 'All',
            child: Row(
              children: [
                Icon(
                  Icons.clear_all,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text('All Categories'),
              ],
            ),
          ),
        ];

        if (categories.isNotEmpty) {
          items.add(const PopupMenuDivider());
        }

        items.add(
          PopupMenuItem(
            value: 'CREATE_NEW_CATEGORY_SPECIAL_KEY', 
            child: Row(
              children: [
                Icon(Icons.add, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text('Create New Category'),
              ],
            ),
          ),
        );

        if (categories.isNotEmpty) {
          items.add(const PopupMenuDivider());
        }

        for (final category in categories) {
          items.add(
            PopupMenuItem(
              value: category,
              child: GestureDetector(
                onLongPress: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, category);
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.category,
                      size: 20,
                      color: selectedCategory == category
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        category,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return items;
      },
    );
  }
}
