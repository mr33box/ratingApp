import 'package:flutter/material.dart';
import '../models/rating_item.dart';
import '../widgets/add_rating_dialog.dart';
import '../widgets/folder_selection_dialog.dart';
import '../widgets/rating_card.dart';
import '../widgets/folder_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/category_filter.dart';
import '../widgets/app_drawer.dart';
import '../services/storage_service.dart';

enum SortOrder { none, best, worst, newest, oldest }

class HomePage extends StatefulWidget {
  final Function(ThemeMode) onThemeModeChanged;

  const HomePage({
    super.key,
    required this.onThemeModeChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<RatingItem> _ratings = [];
  List<String> _categories = [];
  String? _selectedCategoryFilter;
  SortOrder _sortOrder = SortOrder.none;
  bool _isLoading = true;
  
  // Folder Navigation State
  String? _currentFolderId;
  final List<String> _folderStack = [];
  
  // Search State
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Selection Mode State
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final ratings = await StorageService.loadRatings();
      final categories = await StorageService.loadCategories();
      
      setState(() {
        _ratings = ratings;
        _categories = categories;
      });
      
      // Restore current folder
      final savedFolderId = await StorageService.loadCurrentFolder();
      if (savedFolderId != null) {
        // Verify folder still exists
        final folderExists = ratings.any((r) => r.id == savedFolderId && r.isFolder);
        if (folderExists) {
            setState(() {
                _currentFolderId = savedFolderId;
                // Reconstruct stack logic if needed, or just set current. 
                // For simplicity, we just set current, stack might be empty but back should handle it.
                _folderStack.clear(); 
                _folderStack.add(savedFolderId);
            });
        }
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveRatings() async {
    await StorageService.saveRatings(_ratings);
  }

  Future<void> _saveCategories() async {
    await StorageService.saveCategories(_categories);
  }


  void _addRating(RatingItem rating) {
    print('_addRating called with: ${rating.name}, folderIds: ${rating.folderIds}');
    setState(() {
      // Check if this is an update (editing existing item)
      final existingIndex = _ratings.indexWhere((r) => r.id == rating.id);
      if (existingIndex != -1) {
        print('Updating existing rating at index $existingIndex');
        _ratings[existingIndex] = rating;
      } else {
        print('Adding new rating');
        _ratings.add(rating);
      }
    });
    _saveRatings();
    print('Rating saved, total ratings: ${_ratings.length}');
  }

  void _createFolder(String name) {
    final folder = RatingItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      rating: 0, // Folders don't have ratings usually, or could be avg
      createdAt: DateTime.now(),
      isFolder: true,
      folderIds: _currentFolderId != null ? [_currentFolderId!] : [],
    );
    _addRating(folder);
  }

  void _showCreateFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            hintText: 'My Collection',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _createFolder(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _navigateToFolder(String folderId) {
    if (_currentFolderId != folderId) {
        _folderStack.add(folderId);
        setState(() {
          _currentFolderId = folderId;
          _isSelectionMode = false;
          _selectedIds.clear();
        });
        StorageService.saveCurrentFolder(folderId);
    }
  }

  void _navigateBack() {
    if (_folderStack.isNotEmpty) {
      _folderStack.removeLast();
      setState(() {
        _currentFolderId = _folderStack.isNotEmpty ? _folderStack.last : null;
        _isSelectionMode = false;
        _selectedIds.clear();
      });
    } else {
        // Fallback if stack is empty (shouldn't happen if _currentFolderId logic is correct)
        setState(() {
            _currentFolderId = null; 
        });
    }
    StorageService.saveCurrentFolder(_currentFolderId);
  }

  void _deleteRating(String id) {
    setState(() {
      _ratings.removeWhere((rating) => rating.id == id);
    });
    _saveRatings();
  }
  
  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _deleteSelected() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected'),
        content: Text('Are you sure you want to delete ${_selectedIds.length} items?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                _ratings.removeWhere((r) => _selectedIds.contains(r.id));
                _selectedIds.clear();
                _isSelectionMode = false;
              });
              _saveRatings();
              Navigator.pop(context);
            }, 
            child: const Text('Delete')
          ),
        ],
      ),
    );
  }

  void _moveSelected() {
    // Get current folderIds of first selected item (for initial state)
    final firstSelectedItem = _ratings.firstWhere((r) => _selectedIds.contains(r.id));
    
    showDialog(
      context: context,
      builder: (context) => FolderSelectionDialog(
        allItems: _ratings,
        currentFolderId: _currentFolderId,
        currentFolderIds: firstSelectedItem.folderIds,
        onFoldersSelected: (selectedFolderIds) {
          setState(() {
            for (var i = 0; i < _ratings.length; i++) {
              if (_selectedIds.contains(_ratings[i].id)) {
                // Update item with new folderIds
                final item = _ratings[i];
                _ratings[i] = RatingItem(
                  id: item.id,
                  name: item.name,
                  category: item.category,
                  rating: item.rating,
                  description: item.description,
                  color: item.color,
                  imagePath: item.imagePath,
                  createdAt: item.createdAt,
                  isFolder: item.isFolder,
                  folderIds: selectedFolderIds,
                );
              }
            }
            _selectedIds.clear();
            _isSelectionMode = false;
          });
          _saveRatings();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(selectedFolderIds.isEmpty 
                  ? 'Items removed from all folders' 
                  : 'Items added to ${selectedFolderIds.length} folder(s)'),
            ),
          );
        },
      ),
    );
  }

  void _addCategory(String category) {
    if (category.isNotEmpty && !_categories.contains(category)) {
      setState(() {
        _categories.add(category);
      });
      _saveCategories();
    }
  }

  void _deleteCategory(String category) {
    setState(() {
      _categories.remove(category);
      if (_selectedCategoryFilter == category) {
        _selectedCategoryFilter = null;
      }
      _ratings.removeWhere((rating) => rating.category == category);
    });
    _saveCategories();
    _saveRatings();
  }

  void _deleteFolder(String folderId) {
    setState(() {
      // Remove the folder itself
      _ratings.removeWhere((r) => r.id == folderId);
      
      // Update all items that reference this folder
      for (var i = 0; i < _ratings.length; i++) {
        if (_ratings[i].folderIds.contains(folderId)) {
          final item = _ratings[i];
          final updatedFolderIds = List<String>.from(item.folderIds)..remove(folderId);
          _ratings[i] = RatingItem(
            id: item.id,
            name: item.name,
            category: item.category,
            rating: item.rating,
            description: item.description,
            color: item.color,
            imagePath: item.imagePath,
            createdAt: item.createdAt,
            isFolder: item.isFolder,
            folderIds: updatedFolderIds,
          );
        }
      }
      
      // If currently viewing the deleted folder, navigate back
      if (_currentFolderId == folderId) {
        _currentFolderId = null;
        _folderStack.clear();
        StorageService.saveCurrentFolder(null);
      }
    });
    _saveRatings();
  }

  List<RatingItem> get _filteredRatings {
    List<RatingItem> filtered = _ratings;

    // Filter by Search Query
    if (_isSearching && _searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((r) {
        // Search in Name, Description, or Category
        return r.name.toLowerCase().contains(query) || 
               (r.description?.toLowerCase().contains(query) ?? false) ||
               (r.category?.toLowerCase().contains(query) ?? false);
      }).toList();
      // When searching, we show everything (flat list), ignoring folder structure
      return filtered;
    }

    // Filter by current folder
    if (_currentFolderId == null) {
      // Home Mode: Show ALL ratings that are NOT folders
      filtered = filtered.where((r) => !r.isFolder).toList();
    } else {
      // Folder Mode: Show only items that have this folder in their folderIds
      filtered = filtered.where((r) => r.folderIds.contains(_currentFolderId)).toList();
    }

    // Filter by category
    if (_selectedCategoryFilter != null) {
      filtered = filtered
          .where((rating) => rating.category == _selectedCategoryFilter)
          .toList();
    }

    // Sort by rating
    if (_sortOrder == SortOrder.best) {
      filtered.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_sortOrder == SortOrder.worst) {
      filtered.sort((a, b) => a.rating.compareTo(b.rating));
    } else if (_sortOrder == SortOrder.newest) {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sortOrder == SortOrder.oldest) {
      filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    return filtered;
  }

  void _showAddRatingDialog() {
    showDialog(
      context: context,
      builder: (context) => AddRatingDialog(
        categories: _categories,
        currentFolderId: _currentFolderId,
        editingItem: null,
        onAddRating: _addRating,
        onAddCategory: (category) {
          _addCategory(category);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Category "$category" added!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        onDeleteCategory: _deleteCategory,
      ),
    );
  }

  void _showEditRatingDialog(RatingItem rating) {
    showDialog(
      context: context,
      builder: (context) => AddRatingDialog(
        categories: _categories,
        editingItem: rating,
        onAddRating: _addRating,
        onDelete: () => _deleteRating(rating.id),
        onAddCategory: (category) {
          _addCategory(category);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Category "$category" added!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        onDeleteCategory: _deleteCategory,
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    // Determine title
    String title = 'My Rates';
    if (_currentFolderId != null) {
      final folder = _ratings.firstWhere(
        (r) => r.id == _currentFolderId,
        orElse: () => RatingItem(id: '', name: 'Folder', rating: 0, createdAt: DateTime.now()),
      );
      title = '${folder.name}/';
    }

    // Back button handling
    return WillPopScope(
      onWillPop: () async {
        if (_isSelectionMode) {
          setState(() {
            _isSelectionMode = false;
            _selectedIds.clear();
          });
          return false;
        }
        if (_currentFolderId != null) {
          _navigateBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
      drawer: AppDrawer(
        folders: _ratings.where((r) => r.isFolder).toList(),
        currentFolderId: _currentFolderId,
        onFolderSelected: (folderId) {
             if (folderId == null) {
                // If Home is selected, clear everything
                _folderStack.clear();
                setState(() {
                  _currentFolderId = null;
                  _isSelectionMode = false;
                  _selectedIds.clear();
                });
                StorageService.saveCurrentFolder(null);
             } else {
               // Reset stack and start fresh from clicked folder? Or allow deep nav?
               // Usuall drawer navigation resets the stack to that point.
               _folderStack.clear();
               _folderStack.add(folderId);
               setState(() {
                 _currentFolderId = folderId;
                 _isSelectionMode = false;
                 _selectedIds.clear();
               });
               StorageService.saveCurrentFolder(folderId);
             }
        },
        onCreateFolder: _showCreateFolderDialog,
        onDeleteFolder: _deleteFolder,
        onThemeModeChanged: widget.onThemeModeChanged,
      ),
      appBar: AppBar(
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
              )
            : _isSelectionMode
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _isSelectionMode = false;
                        _selectedIds.clear();
                      });
                    },
                  )
                : (_currentFolderId != null 
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back), 
                        onPressed: _navigateBack
                      )
                    : Builder(
                        builder: (context) => IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      )
                    ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : (_isSelectionMode 
                ? Text('${_selectedIds.length} Selected') 
                : Text(title)),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.drive_file_move),
                  tooltip: 'Move to Folder',
                  onPressed: _moveSelected,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete',
                  color: Colors.red,
                  onPressed: _deleteSelected,
                ),
              ]
            : [
          // Search Button (only show if not searching)
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          
          // Ranking filter
          if (!_isSearching)
          PopupMenuButton<SortOrder>(
            tooltip: 'Sort by Rating',
            onSelected: (value) {
              setState(() {
                _sortOrder = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SortOrder.none,
                child: Row(
                  children: [
                    Icon(Icons.clear_all, size: 20),
                    SizedBox(width: 8),
                    Text('No Sort'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: SortOrder.best,
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward, size: 20, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Best Rating First'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: SortOrder.worst,
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Worst Rating First'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: SortOrder.newest,
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 20, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Newest First'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: SortOrder.oldest,
                child: Row(
                  children: [
                    Icon(Icons.history, size: 20, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Oldest First'),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Icon(
                     _sortOrder == SortOrder.best || _sortOrder == SortOrder.worst ? Icons.star : Icons.sort,
                     color: _sortOrder != SortOrder.none ? Theme.of(context).colorScheme.primary : null,
                   ),
                   if (_sortOrder != SortOrder.none)
                     Padding(
                       padding: const EdgeInsets.only(left: 4.0),
                       child: Icon(
                         _sortOrder == SortOrder.best
                             ? Icons.arrow_upward
                             : _sortOrder == SortOrder.worst
                                 ? Icons.arrow_downward
                                 : _sortOrder == SortOrder.newest || _sortOrder == SortOrder.oldest 
                                    ? Icons.access_time 
                                    : Icons.check,
                         size: 14,
                         color: Theme.of(context).colorScheme.primary,
                       ),
                     ),
                ],
              ),
            ),
          ),
          // Category filter
          if (!_isSearching)
          CategoryFilter(
            categories: _categories,
            selectedCategory: _selectedCategoryFilter,
            onCategorySelected: (category) {
              if (category == 'CREATE_NEW_CATEGORY_SPECIAL_KEY') {
                   // Show dialog to create new category
                   final controller = TextEditingController();
                   showDialog(
                     context: context,
                     builder: (context) => AlertDialog(
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                       title: const Text('Create Category'),
                       content: TextField(
                         controller: controller,
                         autofocus: true,
                         decoration: const InputDecoration(
                           labelText: 'Category Name',
                           hintText: 'e.g., Movies, Books',
                         ),
                       ),
                       actions: [
                         TextButton(
                           onPressed: () => Navigator.pop(context),
                           child: const Text('Cancel'),
                         ),
                         ElevatedButton(
                           onPressed: () {
                             if (controller.text.trim().isNotEmpty) {
                               _addCategory(controller.text.trim());
                               setState(() {
                                 _selectedCategoryFilter = controller.text.trim();
                               });
                               Navigator.pop(context);
                               ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(
                                   content: Text('Category "${controller.text.trim()}" created!'),
                                   backgroundColor: Colors.green,
                                 ),
                               );
                             }
                           },
                           child: const Text('Create'),
                         ),
                       ],
                     ),
                   );
               } else {
                  setState(() {
                    _selectedCategoryFilter = category;
                  });
               }
            },
            onDeleteCategory: _deleteCategory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _filteredRatings.isEmpty
              ? (_isSearching 
                  ? Center(child: Text('No results for "$_searchQuery"', style: const TextStyle(fontSize: 16, color: Colors.grey))) 
                  : const EmptyState())
              : Scrollbar(
                  thumbVisibility: true,
                  thickness: 6,
                  radius: const Radius.circular(3),
                  child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _filteredRatings.length,
                  itemBuilder: (context, index) {
                    final item = _filteredRatings[index];
                    
                    if (item.isFolder) {
                        return FolderCard(
                          folder: item,
                          itemCount: _ratings.where((r) => r.folderIds.contains(item.id)).length,
                          isSelected: _selectedIds.contains(item.id),
                          onTap: () {
                              if (_isSelectionMode) {
                                  _toggleSelection(item.id);
                              } else {
                                  _navigateToFolder(item.id);
                              }
                          },
                          onLongPress: () => _toggleSelection(item.id),
                        );
                    }
                    
                    // Logic to find folder names for this item
                    String? parentFolderName;
                    if (item.folderIds.isNotEmpty) {
                       // Find names of all folders this item belongs to
                       final folderNames = _ratings
                           .where((r) => r.isFolder && item.folderIds.contains(r.id))
                           .map((r) => r.name)
                           .join(', ');
                       if (folderNames.isNotEmpty) {
                           parentFolderName = folderNames;
                       }
                    }
                    
                    return RatingCard(
                      rating: item,
                      folderName: parentFolderName,
                      // Hide delete button in card, use long press batch delete
                      onEdit: () => _showEditRatingDialog(item),
                      isSelected: _selectedIds.contains(item.id),
                      onTap: _isSelectionMode 
                          ? () => _toggleSelection(item.id) 
                          : null, // Pass null to let RatingCard handle expansion
                      onLongPress: () => _toggleSelection(item.id),
                    );
                  },
                ),
              ),
      floatingActionButton: _isSelectionMode ? null : FloatingActionButton(
        onPressed: _showAddRatingDialog,
        tooltip: 'Add Rating',
        child: const Icon(Icons.add),
      ),
    ),
    );
  }
}
