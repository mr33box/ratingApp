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

enum SortOrder { none, best, worst }

class HomePage extends StatefulWidget {
  final Function(ThemeMode) onThemeModeChanged;

  const HomePage({
    super.key,
    required this.onThemeModeChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<RatingItem> _ratings = [];
  List<String> _categories = [];
  String? _selectedCategoryFilter;
  SortOrder _sortOrder = SortOrder.none;
  bool _isLoading = true;
  
  // Folder Navigation State
  String? _currentFolderId;
  
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
    setState(() {
      // Check if this is an update (editing existing item)
      final existingIndex = _ratings.indexWhere((r) => r.id == rating.id);
      if (existingIndex != -1) {
        _ratings[existingIndex] = rating;
      } else {
        // Add to current folder if creating new
        if (rating.parentId == null && _currentFolderId != null) {
           // If we are in a specific folder, ensure new item gets that folder ID
           // Note: The dialog now handles this logic via parentId param, but this is a safety check
           // In All Items mode (_currentFolderId == null), parentId defaults to null
        }
        _ratings.add(rating);
      }
    });
    _saveRatings();
  }

  void _createFolder(String name) {
    final folder = RatingItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      rating: 0, // Folders don't have ratings usually, or could be avg
      createdAt: DateTime.now(),
      isFolder: true,
      parentId: _currentFolderId,
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
    setState(() {
      _currentFolderId = folderId;
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _navigateBack() {
    if (_currentFolderId != null) {
      // Find current folder to get its parent
      final currentFolder = _ratings.firstWhere(
        (r) => r.id == _currentFolderId, 
        orElse: () => RatingItem(id: '', name: '', rating: 0, createdAt: DateTime.now())
      );
      
      setState(() {
        _currentFolderId = currentFolder.parentId;
         _isSelectionMode = false;
         _selectedIds.clear();
      });
    }
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
    showDialog(
      context: context,
      builder: (context) => FolderSelectionDialog(
        allItems: _ratings,
        currentFolderId: _currentFolderId,
        onFolderSelected: (folderId) {
          setState(() {
            for (var i = 0; i < _ratings.length; i++) {
              if (_selectedIds.contains(_ratings[i].id)) {
                // Create copy with new parentId
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
                  parentId: folderId,
                );
              }
            }
            _selectedIds.clear();
            _isSelectionMode = false;
          });
          _saveRatings();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Items moved')),
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

  List<RatingItem> get _filteredRatings {
    List<RatingItem> filtered = _ratings;

    // Filter by current folder
    if (_currentFolderId == null) {
      // Home Mode: Show ALL ratings that are NOT folders
      filtered = filtered.where((r) => !r.isFolder).toList();
    } else {
      // Folder Mode: Show only items directly inside this folder
      filtered = filtered.where((r) => r.parentId == _currentFolderId).toList();
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
    }

    return filtered;
  }

  void _showAddRatingDialog() {
    showDialog(
      context: context,
      builder: (context) => AddRatingDialog(
        categories: _categories,
        parentId: _currentFolderId,
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
    // Determine title
    String title = 'Rating App';
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
             _navigateToFolder(folderId ?? 'root_reset_null'); // Handle null passing properly
             if (folderId == null) {
                // If Home is selected, clear everything
                setState(() {
                  _currentFolderId = null;
                  _isSelectionMode = false;
                  _selectedIds.clear();
                });
             } else {
               _navigateToFolder(folderId);
             }
        },
        onCreateFolder: _showCreateFolderDialog,
        onThemeModeChanged: widget.onThemeModeChanged,
      ),
      appBar: AppBar(
        leading: _isSelectionMode
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
                // In sub-folder: Show back button
                ? IconButton(
                    icon: const Icon(Icons.arrow_back), 
                    onPressed: _navigateBack
                  )
                // At root: Show hamburger (Flutter does this automatically if leading is null, but we explicitly control it)
                : Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  )
                ),
        title: _isSelectionMode 
            ? Text('${_selectedIds.length} Selected') 
            : Text(title),
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
          // Ranking filter
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
                    Text('Best First'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: SortOrder.worst,
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Worst First'),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sort),
                  if (_sortOrder != SortOrder.none)
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Icon(
                        _sortOrder == SortOrder.best
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Category filter
          CategoryFilter(
            categories: _categories,
            selectedCategory: _selectedCategoryFilter,
            onCategorySelected: (category) {
              setState(() {
                _selectedCategoryFilter = category;
              });
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
              ? const EmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _filteredRatings.length,
                  itemBuilder: (context, index) {
                    final item = _filteredRatings[index];
                    
                    if (item.isFolder) {
                        return FolderCard(
                          folder: item,
                          itemCount: _ratings.where((r) => r.parentId == item.id).length,
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
                    
                    String? parentFolderName;
                    if (item.parentId != null) {
                      try {
                        parentFolderName = _ratings
                            .firstWhere((r) => r.id == item.parentId)
                            .name;
                      } catch (_) {}
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
      floatingActionButton: _isSelectionMode ? null : FloatingActionButton(
        onPressed: _showAddRatingDialog,
        tooltip: 'Add Rating',
        child: const Icon(Icons.add),
      ),
    ));
  }
}
