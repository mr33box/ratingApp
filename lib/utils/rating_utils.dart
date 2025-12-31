import 'package:flutter/material.dart';

class RatingUtils {
  static Color getRatingColor(double rating) {
    if (rating >= 9.0) return Colors.green[800]!;
    if (rating >= 7.0) return Colors.green;
    if (rating >= 5.0) return Colors.amber;
    if (rating >= 3.0) return Colors.orange;
    return Colors.red;
  }
}



