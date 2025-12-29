import 'dart:io';
import 'package:flutter/material.dart';
import '../models/rating_item.dart';
import '../utils/rating_utils.dart';

class RatingCard extends StatefulWidget {
  final RatingItem rating;
  final VoidCallback? onDelete; // Made optional as we might use batch delete
  final VoidCallback onEdit;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final String? folderName;

  const RatingCard({
    super.key,
    required this.rating,
    this.onDelete,
    required this.onEdit,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.folderName,
  });

  @override
  State<RatingCard> createState() => _RatingCardState();
}

class _RatingCardState extends State<RatingCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final ratingColor = RatingUtils.getRatingColor(widget.rating.rating);
    
    // Determine text color based on card background brightness
    final isDark = widget.rating.color != null 
        ? widget.rating.color!.computeLuminance() < 0.5
        : theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    
    // Rating color: white if color is chosen, otherwise use rating color
    final ratingTextColor = widget.rating.color != null ? Colors.white : ratingColor;
    final ratingIconColor = widget.rating.color != null ? Colors.white : ratingColor;

    return GestureDetector(
      onTap: widget.onTap ?? () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      onLongPress: widget.onLongPress,
      child: Card(
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        elevation: widget.isSelected ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: widget.isSelected 
            ? BorderSide(color: colorScheme.primary, width: 3)
            : BorderSide.none,
        ),
        color: widget.rating.color != null 
            ? widget.rating.color!.withOpacity(0.9)
            : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Color background on left half (behind content)
              if (widget.rating.color != null)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.rating.color!.withOpacity(0.9),
                    ),
                  ),
                ),
              // Image background on right half (opposite of content) with smooth gradient fade
              if (widget.rating.imagePath != null)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: Stack(
                    children: [
                      Image.file(
                        File(widget.rating.imagePath!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      // Smooth gradient fade from right (transparent) to left (color or theme)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                              // More stops for smoother transition
                              stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                              colors: [
                                Colors.transparent,
                                Colors.transparent.withOpacity(0.1),
                                (widget.rating.color != null
                                        ? widget.rating.color!.withOpacity(0.4)
                                        : (theme.brightness == Brightness.dark
                                            ? colorScheme.surfaceContainerHighest.withOpacity(0.4)
                                            : colorScheme.surfaceContainerHighest.withOpacity(0.4))),
                                (widget.rating.color != null
                                        ? widget.rating.color!.withOpacity(0.85)
                                        : (theme.brightness == Brightness.dark
                                            ? colorScheme.surfaceContainerHighest.withOpacity(0.85)
                                            : colorScheme.surfaceContainerHighest.withOpacity(0.85))),
                                widget.rating.color != null
                                    ? widget.rating.color!.withOpacity(0.98)
                                    : (theme.brightness == Brightness.dark
                                        ? colorScheme.surfaceContainerHighest
                                        : colorScheme.surfaceContainerHighest),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.rating.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                        Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: textColor.withOpacity(0.7),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (widget.isSelected)
                         Padding(
                           padding: const EdgeInsets.only(bottom: 8.0),
                           child: Row(
                               children: [
                                   Icon(Icons.check_circle, color: ratingTextColor, size: 20),
                                   const SizedBox(width: 8),
                                   Text('Selected', style: TextStyle(color: ratingTextColor, fontWeight: FontWeight.bold)),
                               ],
                           ),
                         ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          color: ratingIconColor,
                          size: 24,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.rating.rating.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: ratingTextColor,
                          ),
                        ),
                      ],
                    ),
                    // Expanded content
                    if (_isExpanded) ...[
                      if (widget.rating.category != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: textColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.category,
                                    size: 16,
                                    color: textColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.rating.category!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (widget.folderName != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                             Icon(
                               Icons.folder_open,
                               size: 16,
                               color: textColor.withOpacity(0.7),
                             ),
                             const SizedBox(width: 8),
                             Text(
                               'In: ${widget.folderName}',
                               style: TextStyle(
                                 fontSize: 13,
                                 fontWeight: FontWeight.w500,
                                 color: textColor.withOpacity(0.8),
                                 fontStyle: FontStyle.italic,
                               ),
                             ),
                          ],
                        ),
                      ],
                      if (widget.rating.description != null &&
                          widget.rating.description!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: textColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.rating.description!,
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor.withOpacity(0.9),
                              height: 1.4,
                            ),
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      // Edit Button in expanded view
                         const SizedBox(height: 16),
                         Row(
                           mainAxisAlignment: MainAxisAlignment.end,
                           children: [
                             TextButton.icon(
                               onPressed: widget.onEdit,
                               icon: Icon(Icons.edit, color: textColor),
                               label: Text('Edit Data', style: TextStyle(color: textColor)),
                               style: TextButton.styleFrom(
                                 backgroundColor: textColor.withOpacity(0.1),
                               ),
                             ),
                           ],
                         ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
