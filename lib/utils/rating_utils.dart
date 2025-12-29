import 'package:flutter/material.dart';

class RatingUtils {
  static Color getRatingColor(double rating) {
    if (rating >= 8) return Colors.green;
    if (rating >= 6) return Colors.orange;
    if (rating >= 4) return Colors.amber;
    return Colors.red;
  }
}



