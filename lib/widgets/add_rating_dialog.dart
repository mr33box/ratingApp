import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/rating_item.dart';
import '../utils/rating_utils.dart';

class AddRatingDialog extends StatefulWidget {
  final List<String> categories;
  final Function(RatingItem) onAddRating;
  final Function(String) onAddCategory;
  final Function(String) onDeleteCategory;
  final VoidCallback? onDelete;
  final RatingItem? editingItem;
  final String? parentId;

  const AddRatingDialog({
    super.key,
    required this.categories,
    required this.onAddRating,
    required this.onAddCategory,
    required this.onDeleteCategory,
    this.onDelete,
    this.editingItem,
    this.parentId,
  });

  @override
  State<AddRatingDialog> createState() => _AddRatingDialogState();
}

class _AddRatingDialogState extends State<AddRatingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _newCategoryController = TextEditingController();
  
  String? _selectedCategory;
  double _rating = 5.0;
  bool _isCreatingCategory = false;
  Color? _selectedColor;
  String? _selectedImagePath;
  final ImagePicker _picker = ImagePicker();

  final List<Color> _colorOptions = [
    
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.amber,
    Colors.indigo,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editingItem != null) {
      _loadEditingData();
    } else {
      _resetForm();
    }
  }

  void _loadEditingData() {
    final item = widget.editingItem!;
    _nameController.text = item.name;
    _descriptionController.text = item.description ?? '';
    _selectedCategory = item.category;
    _rating = item.rating;
    _selectedColor = item.color;
    _selectedImagePath = item.imagePath;
    _isCreatingCategory = false;
  }

  void _resetForm() {
    _nameController.clear();
    _descriptionController.clear();
    _newCategoryController.clear();
    _selectedCategory = null;
    _rating = 5.0;
    _isCreatingCategory = false;
    _selectedColor = null;
    _selectedImagePath = null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  void _saveRating() {
    // Validate form if currentState exists
    final formState = _formKey.currentState;
    if (formState != null && !formState.validate()) {
      // Form validation failed, errors will be shown automatically
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a name'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final rating = RatingItem(
        id: widget.editingItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        category: _selectedCategory,
        rating: _rating,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        color: _selectedColor,
        imagePath: _selectedImagePath,
        createdAt: widget.editingItem?.createdAt ?? DateTime.now(),
        // FIX: Persist the parentId (folder) - prioritize existing item's parent, then passed parentId
        parentId: widget.editingItem?.parentId ?? widget.parentId,
        isFolder: widget.editingItem?.isFolder ?? false,
      );

      widget.onAddRating(rating);
      
      // Close the dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving rating: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _createCategory() {
    final categoryName = _newCategoryController.text.trim();
    if (categoryName.isEmpty) {
      return;
    }

    widget.onAddCategory(categoryName);
    setState(() {
      _selectedCategory = categoryName;
      _isCreatingCategory = false;
      _newCategoryController.clear();
    });
  }

  void _handleCategorySelection(String? value) {
    if (value == 'CREATE_NEW') {
      setState(() {
        _isCreatingCategory = true;
        _selectedCategory = null;
      });
    } else {
      setState(() {
        _selectedCategory = value;
        _isCreatingCategory = false;
      });
    }
  }

  void _showDeleteCategoryDialog(String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "$category"?\n\nAll ratings in this category will also be deleted.'),
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
              widget.onDeleteCategory(category);
              if (_selectedCategory == category) {
                setState(() {
                  _selectedCategory = null;
                });
              }
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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        // Copy image to app directory for persistence
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = File('${appDir.path}/$fileName');
        await File(image.path).copy(savedImage.path);
        
        setState(() {
          _selectedImagePath = savedImage.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImagePath = null;
    });
  }

  void _showManualRatingInput() {
    final controller = TextEditingController(text: _rating.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Rating'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Rating (1.0 - 10.0)',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            _updateManualRating(value);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateManualRating(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  void _updateManualRating(String value) {
    if (value.isEmpty) return;
    
    // Replace comma with dot for international support
    final cleanValue = value.replaceAll(',', '.');
    final double? parsed = double.tryParse(cleanValue);
    
    if (parsed != null) {
      if (parsed >= 1.0 && parsed <= 10.0) {
        setState(() {
          _rating = parsed;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Rating must be between 1.0 and 10.0')),
        );
      }
    }
  }

  void _showDeleteDialog() {
    if (widget.onDelete == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Rating'),
        content: Text('Are you sure you want to delete "${_nameController.text}"?'),
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
              Navigator.of(context).pop(); // Close delete dialog
              Navigator.of(context).pop(); // Close edit dialog
              widget.onDelete!();
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

  void _showColorPicker() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Choose Color'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Remove color option (only show when editing and color is set)
            if (_selectedColor != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedColor = null;
                    });
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text('Remove Color'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.errorContainer,
                    foregroundColor: colorScheme.onErrorContainer,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colorOptions.map((color) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedColor == color ? Colors.black : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: _selectedColor == color
                        ? const Icon(Icons.check, color: Colors.white, size: 24)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ratingColor = RatingUtils.getRatingColor(_rating);

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header with color picker and delete button
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _showColorPicker,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _selectedColor ?? colorScheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.outline.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: _selectedColor == null
                              ? Icon(
                                  Icons.add,
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                  size: 20,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.editingItem != null ? 'Edit Rating' : 'Add Rating',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_selectedColor == null)
                              Text(
                                'Tap circle to add color',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (widget.editingItem != null && widget.onDelete != null)
                        IconButton(
                          onPressed: _showDeleteDialog,
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.red,
                          tooltip: 'Delete',
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Name field
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      hintText: 'Book, Series, Film, Show, etc.',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      ),
                      focusedErrorBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      ),
                      prefixIcon: const Icon(Icons.title),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      errorStyle: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Category section
                  if (!_isCreatingCategory)
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category (Optional)',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        prefixIcon: const Icon(Icons.category),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('No Category'),
                        ),
                        ...widget.categories.map((category) =>
                            DropdownMenuItem<String>(
                              value: category,
                              child: GestureDetector(
                                onLongPress: () => _showDeleteCategoryDialog(category),
                                child: Text(category),
                              ),
                            )),
                        const DropdownMenuItem<String>(
                          value: 'CREATE_NEW',
                          child: Row(
                            children: [
                              Icon(Icons.add_circle_outline, size: 20),
                              SizedBox(width: 8),
                              Text('Create New Category'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: _handleCategorySelection,
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _newCategoryController,
                            decoration: InputDecoration(
                              labelText: 'Category Name',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              prefixIcon: const Icon(Icons.category),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest,
                            ),
                            autofocus: true,
                            onFieldSubmitted: (_) => _createCategory(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _createCategory,
                          icon: const Icon(Icons.check),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _isCreatingCategory = false;
                              _newCategoryController.clear();
                            });
                          },
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  // Rating section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Rating',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            InkWell(
                              onTap: _showManualRatingInput,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star, color: ratingColor, size: 24),
                                    const SizedBox(width: 6),
                                    Text(
                                      _rating.toStringAsFixed(2),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: ratingColor,
                                        decoration: TextDecoration.underline,
                                        decorationColor: ratingColor.withOpacity(0.5),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.edit, size: 16, color: ratingColor.withOpacity(0.7)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: colorScheme.primary,
                            inactiveTrackColor: colorScheme.outline.withOpacity(0.3),
                            thumbColor: colorScheme.primary,
                            overlayColor: colorScheme.primary.withOpacity(0.2),
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 12,
                            ),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: _rating,
                            min: 1.0,
                            max: 10.0,
                            divisions: 90,
                            label: _rating.toStringAsFixed(2),
                            onChanged: (value) {
                              setState(() {
                                _rating = value;
                              });
                            },
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '1.0',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            Text(
                              '10.0',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Description field
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Add any notes...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      prefixIcon: const Icon(Icons.description),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  // Image picker section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Background Image (Optional)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_selectedImagePath != null)
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(_selectedImagePath!),
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  onPressed: _removeImage,
                                  icon: const Icon(Icons.close),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.black54,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image),
                            label: const Text('Choose Photo'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _saveRating,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
