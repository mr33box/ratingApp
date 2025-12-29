import 'package:flutter/material.dart';
import '../models/rating_item.dart';

class FolderSelectionDialog extends StatelessWidget {
  final List<RatingItem> allItems;
  final String? currentFolderId;
  final Function(String?) onFolderSelected;

  const FolderSelectionDialog({
    super.key,
    required this.allItems,
    required this.currentFolderId,
    required this.onFolderSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Get all folders except the current one (can't move into self, though we are moving items not folders usually)
    // If moving folders is allowed, need to prevent cycles. For now let's assume valid.
    final folders = allItems.where((i) => i.isFolder && i.id != currentFolderId).toList();

    return AlertDialog(
      title: const Text('Move to Folder'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home (Root)'),
              onTap: () {
                onFolderSelected(null);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            if (folders.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No other folders available.', textAlign: TextAlign.center),
              )
            else
              ...folders.map((folder) => ListTile(
                    leading: Icon(Icons.folder, color: folder.color),
                    title: Text(folder.name),
                    subtitle: folder.parentId != null ? const Text('Sub-folder') : null,
                    onTap: () {
                      onFolderSelected(folder.id);
                      Navigator.pop(context);
                    },
                  )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
