import 'package:flutter/material.dart';
import '../models/rating_item.dart';

class FolderSelectionDialog extends StatefulWidget {
  final List<RatingItem> allItems;
  final String? currentFolderId;
  final Function(List<String>) onFoldersSelected; // Changed to list
  final List<String>? currentFolderIds; // Current folders the item is in

  const FolderSelectionDialog({
    super.key,
    required this.allItems,
    required this.currentFolderId,
    required this.onFoldersSelected,
    this.currentFolderIds,
  });

  @override
  State<FolderSelectionDialog> createState() => _FolderSelectionDialogState();
}

class _FolderSelectionDialogState extends State<FolderSelectionDialog> {
  late Set<String> _selectedFolderIds;

  @override
  void initState() {
    super.initState();
    // Initialize with current folders
    _selectedFolderIds = Set<String>.from(widget.currentFolderIds ?? []);
  }

  @override
  Widget build(BuildContext context) {
    final folders = widget.allItems.where((i) => i.isFolder && i.id != widget.currentFolderId).toList();

    return AlertDialog(
      title: const Text('Select Folders'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            const Text(
              'Select which folders this item should appear in:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (folders.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No folders available. Create a folder first!', textAlign: TextAlign.center),
              )
            else
              ...folders.map((folder) => CheckboxListTile(
                    value: _selectedFolderIds.contains(folder.id),
                    onChanged: (bool? checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedFolderIds.add(folder.id);
                        } else {
                          _selectedFolderIds.remove(folder.id);
                        }
                      });
                    },
                    title: Text(folder.name),
                    subtitle: folder.folderIds.isNotEmpty ? const Text('Sub-folder') : null,
                    secondary: Icon(Icons.folder, color: folder.color),
                  )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onFoldersSelected(_selectedFolderIds.toList());
            Navigator.pop(context);
          },
          child: Text(_selectedFolderIds.isEmpty ? 'Remove from all' : 'Save (${_selectedFolderIds.length})'),
        ),
      ],
    );
  }
}
