import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/rating_item.dart';
import '../services/storage_service.dart';

class AppDrawer extends StatelessWidget {
  final List<RatingItem> folders;
  final String? currentFolderId;
  final Function(String?) onFolderSelected;
  final VoidCallback onCreateFolder;
  final Function(ThemeMode) onThemeModeChanged;
  final bool isWeakMode; // Assuming light mode logic here, renaming for clarity or use theme
  
  const AppDrawer({
    super.key,
    required this.folders,
    required this.currentFolderId,
    required this.onFolderSelected,
    required this.onCreateFolder,
    required this.onThemeModeChanged,
    this.isWeakMode = false, // Added default value
  });

  void _showContactUs(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Contact Us'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'For support or feedback, please contact us at:\n',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.email, size: 20),
                const SizedBox(width: 8),
                const SelectableText(
                  'mr33box33dz@gmail.com',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                 Icon(Icons.phone, size: 20),
                 SizedBox(width: 8),
                 SelectableText(
                  '0792624962',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About'),
        content: const Text(
          'Rating App\n\n'
          'Version: 1.0.0\n\n'
          'A simple app to track and rate your favorite books, '
          'series, films, and shows.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _copyDataToClipboard(BuildContext context) async {
    try {
      final ratings = await StorageService.loadRatings();
      
      final Map<String?, List<RatingItem>> grouped = {};
      for (var item in ratings) {
        if (!grouped.containsKey(item.parentId)) {
          grouped[item.parentId] = [];
        }
        grouped[item.parentId]!.add(item);
      }
      
      final buffer = StringBuffer();
      _formatItems(grouped[null] ?? [], grouped, buffer, 0);
      
      await Clipboard.setData(ClipboardData(text: buffer.toString()));
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data copied to clipboard!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error copying data: $e')),
        );
      }
    }
  }

  void _formatItems(
    List<RatingItem> items, 
    Map<String?, List<RatingItem>> grouped, 
    StringBuffer buffer, 
    int indentLevel
  ) {
    final indent = ' ' * (indentLevel * 4);
    
    for (var item in items) {
      if (item.isFolder) {
        buffer.writeln('${indent}folder_name : ${item.name}');
        
        final children = grouped[item.id] ?? [];
        if (children.isNotEmpty) {
           _formatItems(children, grouped, buffer, indentLevel + 1);
        }
        buffer.writeln(); 
      } else {
        buffer.writeln('${indent}name : ${item.name}');
        if (item.category != null) {
          buffer.writeln('${indent}category : ${item.category}');
        }
        buffer.writeln('${indent}rate : ${item.rating.toStringAsFixed(1)}');
        buffer.writeln(); 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Drawer(
      child: Column(
        children: [
           UserAccountsDrawerHeader(
            decoration: BoxDecoration(

              gradient: LinearGradient(
                colors: isDark 
                    ? [
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                        Theme.of(context).colorScheme.surface,
                      ] 
                    : [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: const Text(
              'Rating App',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            accountEmail: const Text('Keep track of what matches your taste'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.star_rounded,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Navigation Section
                ListTile(
                  leading: const Icon(Icons.home_rounded),
                  title: const Text('Home'),
                  selected: currentFolderId == null,
                  onTap: () {
                    onFolderSelected(null);
                    Navigator.pop(context);
                  },
                ),
                
                ExpansionTile(
                  leading: const Icon(Icons.folder_open_rounded),
                  title: const Text('Folders'),
                  initiallyExpanded: true,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.create_new_folder_outlined),
                      title: const Text('Create New Folder'),
                      onTap: () {
                        Navigator.pop(context);
                        onCreateFolder();
                      },
                    ),
                    if (folders.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No folders yet', 
                          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)
                        ),
                      ),
                    ...folders.map((folder) => ListTile(
                      contentPadding: const EdgeInsets.only(left: 32, right: 16),
                      leading: Icon(
                        Icons.folder_rounded, 
                        color: folder.color ?? Theme.of(context).colorScheme.primary
                      ),
                      title: Text(folder.name),
                      selected: currentFolderId == folder.id,
                      onTap: () {
                        onFolderSelected(folder.id);
                        Navigator.pop(context);
                      },
                    )),
                  ],
                ),
                
                const Divider(),
                
                // Settings Section
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                
                ListTile(
                  leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                  title: const Text('Dark Mode'),
                  trailing: Switch(
                    value: isDark,
                    onChanged: (value) {
                       onThemeModeChanged(value ? ThemeMode.dark : ThemeMode.light);
                    },
                  ),
                ),
                
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text('Copy All Data'),
                  onTap: () {
                    Navigator.pop(context);
                    _copyDataToClipboard(context);
                  },
                ),
                 
                ListTile(
                  leading: const Icon(Icons.contact_support),
                  title: const Text('Contact Us'),
                  onTap: () => _showContactUs(context),
                ),
                
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  onTap: () => _showAbout(context),
                ),
              ],
            ),
          ),
          
          // Footer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'v1.0.0',
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
