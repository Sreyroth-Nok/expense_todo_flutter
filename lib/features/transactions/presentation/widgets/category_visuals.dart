import 'package:flutter/material.dart';

/// The fixed icon set a category can use. Firestore stores only the key.
abstract final class CategoryIcons {
  static const Map<String, IconData> byKey = {
    'food': Icons.restaurant_rounded,
    'transport': Icons.directions_bus_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'bills': Icons.receipt_long_rounded,
    'health': Icons.favorite_rounded,
    'entertainment': Icons.movie_rounded,
    'education': Icons.school_rounded,
    'home': Icons.home_rounded,
    'coffee': Icons.local_cafe_rounded,
    'phone': Icons.phone_android_rounded,
    'travel': Icons.flight_rounded,
    'pets': Icons.pets_rounded,
    'salary': Icons.payments_rounded,
    'business': Icons.storefront_rounded,
    'gift': Icons.card_giftcard_rounded,
    'investment': Icons.trending_up_rounded,
    'other': Icons.category_rounded,
  };

  static IconData of(String key) => byKey[key] ?? Icons.category_rounded;

  /// Colors offered when creating a category.
  static const List<int> palette = [
    0xFF0F766E, 0xFF16A34A, 0xFFF0B429, 0xFFD97706, 0xFFDC2626,
    0xFFDB2777, 0xFF7C3AED, 0xFF4F46E5, 0xFF2563EB, 0xFF0891B2,
    0xFF6B7280,
  ];
}

/// Rounded square with the category icon on a tinted background.
class CategoryIconBadge extends StatelessWidget {
  const CategoryIconBadge({
    super.key,
    required this.iconKey,
    required this.colorValue,
    this.size = 44,
  });

  final String iconKey;
  final int colorValue;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Color(colorValue);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(CategoryIcons.of(iconKey), color: color, size: size * 0.52),
    );
  }
}
