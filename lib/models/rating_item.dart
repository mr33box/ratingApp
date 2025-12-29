import 'package:flutter/material.dart';

class RatingItem {
  final String id;
  final String name;
  final String? category;
  final double rating;
  final String? description;
  final Color? color;
  final String? imagePath;
  final DateTime createdAt;
  final bool isFolder;
  final String? parentId;

  RatingItem({
    required this.id,
    required this.name,
    this.category,
    required this.rating,
    this.description,
    this.color,
    this.imagePath,
    required this.createdAt,
    this.isFolder = false,
    this.parentId,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'rating': rating,
      'description': description,
      'color': color != null ? {
        'r': color!.red,
        'g': color!.green,
        'b': color!.blue,
        'a': color!.alpha,
      } : null,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'isFolder': isFolder,
      'parentId': parentId,
    };
  }

  // Create from JSON
  factory RatingItem.fromJson(Map<String, dynamic> json) {
    Color? color;
    if (json['color'] != null) {
      final colorData = json['color'] as Map<String, dynamic>;
      color = Color.fromARGB(
        colorData['a'] as int,
        colorData['r'] as int,
        colorData['g'] as int,
        colorData['b'] as int,
      );
    }

    return RatingItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String?,
      rating: (json['rating'] as num).toDouble(),
      description: json['description'] as String?,
      color: color,
      imagePath: json['imagePath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isFolder: json['isFolder'] as bool? ?? false,
      parentId: json['parentId'] as String?,
    );
  }
}
