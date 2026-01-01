import 'package:flutter/material.dart';
import '../config/theme.dart';

class Category {
  final String name;
  final String displayName;
  final String icon;
  final Color color;

  Category({
    required this.name,
    required this.displayName,
    required this.icon,
    required this.color,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      name: json['name'] ?? '',
      displayName: json['displayName'] ?? json['name'] ?? '',
      icon: json['icon'] ?? '📦',
      color: AppColors.categoryColors[json['name']] ?? AppColors.textSecondary,
    );
  }

  // Predefined categories list
  static List<Category> get all {
    return [
      Category(name: 'clothes', displayName: 'Clothes', icon: '👕', color: AppColors.categoryColors['clothes']!),
      Category(name: 'drinks', displayName: 'Drinks', icon: '🍺', color: AppColors.categoryColors['drinks']!),
      Category(name: 'education', displayName: 'Education', icon: '📚', color: AppColors.categoryColors['education']!),
      Category(name: 'food', displayName: 'Food', icon: '🍔', color: AppColors.categoryColors['food']!),
      Category(name: 'fuel', displayName: 'Fuel', icon: '⛽', color: AppColors.categoryColors['fuel']!),
      Category(name: 'fun', displayName: 'Fun', icon: '🎮', color: AppColors.categoryColors['fun']!),
      Category(name: 'health', displayName: 'Health', icon: '💊', color: AppColors.categoryColors['health']!),
      Category(name: 'hotel', displayName: 'Hotel', icon: '🏨', color: AppColors.categoryColors['hotel']!),
      Category(name: 'personal', displayName: 'Personal', icon: '👤', color: AppColors.categoryColors['personal']!),
      Category(name: 'pets', displayName: 'Pets', icon: '🐾', color: AppColors.categoryColors['pets']!),
      Category(name: 'restaurants', displayName: 'Restaurants', icon: '🍽️', color: AppColors.categoryColors['restaurants']!),
      Category(name: 'tips', displayName: 'Tips', icon: '💰', color: AppColors.categoryColors['tips']!),
      Category(name: 'transport', displayName: 'Transport', icon: '🚗', color: AppColors.categoryColors['transport']!),
      Category(name: 'others', displayName: 'Others', icon: '📦', color: AppColors.categoryColors['others']!),
    ];
  }

  static Category getByName(String name) {
    return all.firstWhere(
      (cat) => cat.name.toLowerCase() == name.toLowerCase(),
      orElse: () => all.last, // Return 'others' as default
    );
  }
}
