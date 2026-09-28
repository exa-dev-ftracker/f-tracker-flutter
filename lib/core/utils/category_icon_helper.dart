import 'package:flutter/material.dart';

class CategoryIconItem {
  final String key;
  final String label;
  final IconData iconData;

  const CategoryIconItem({
    required this.key,
    required this.label,
    required this.iconData,
  });
}

class CategoryIconHelper {
  CategoryIconHelper._();

  static const List<CategoryIconItem> availableIcons = [
    CategoryIconItem(key: 'i-heroicons-tag', label: 'Tag', iconData: Icons.local_offer_rounded),
    CategoryIconItem(key: 'i-heroicons-shopping-cart', label: 'Cart', iconData: Icons.shopping_cart_rounded),
    CategoryIconItem(key: 'fastfood', label: 'Food', iconData: Icons.restaurant_rounded),
    CategoryIconItem(key: 'coffee', label: 'Coffee', iconData: Icons.local_cafe_rounded),
    CategoryIconItem(key: 'i-heroicons-truck', label: 'Transport', iconData: Icons.directions_car_rounded),
    CategoryIconItem(key: 'i-heroicons-home', label: 'Home', iconData: Icons.home_rounded),
    CategoryIconItem(key: 'i-heroicons-heart', label: 'Health', iconData: Icons.favorite_rounded),
    CategoryIconItem(key: 'i-heroicons-academic-cap', label: 'Education', iconData: Icons.school_rounded),
    CategoryIconItem(key: 'i-heroicons-briefcase', label: 'Work', iconData: Icons.work_rounded),
    CategoryIconItem(key: 'i-heroicons-gift', label: 'Gift', iconData: Icons.card_giftcard_rounded),
    CategoryIconItem(key: 'i-heroicons-musical-note', label: 'Entertainment', iconData: Icons.music_note_rounded),
    CategoryIconItem(key: 'i-heroicons-banknotes', label: 'Money', iconData: Icons.account_balance_wallet_rounded),
    CategoryIconItem(key: 'i-heroicons-credit-card', label: 'Card', iconData: Icons.credit_card_rounded),
    CategoryIconItem(key: 'i-heroicons-chart-bar', label: 'Investment', iconData: Icons.trending_up_rounded),
    CategoryIconItem(key: 'receipt_long', label: 'Bills', iconData: Icons.receipt_long_rounded),
    CategoryIconItem(key: 'flight', label: 'Travel', iconData: Icons.flight_rounded),
  ];

  /// Resolves an IconData from an icon string (e.g. from Heroicons or Backend)
  /// with intelligent fallback based on category name.
  static IconData getIconData(String? icon, [String? categoryName]) {
    final key = (icon ?? '').toLowerCase().trim();
    final nameKey = (categoryName ?? '').toLowerCase().trim();

    // 1. Direct Specific Icon Key Mapping (excluding generic 'tag')
    if (key.contains('shopping-cart') || key.contains('cart') || key == 'shopping_bag') {
      return Icons.shopping_cart_rounded;
    }
    if (key.contains('truck') || key.contains('car') || key == 'directions_car') {
      return Icons.directions_car_rounded;
    }
    if (key.contains('fastfood') || key.contains('food') || key.contains('restaurant') || key.contains('cake') || key.contains('cup')) {
      return Icons.restaurant_rounded;
    }
    if (key.contains('coffee') || key.contains('cafe')) {
      return Icons.local_cafe_rounded;
    }
    if (key.contains('home') || key.contains('house')) {
      return Icons.home_rounded;
    }
    if (key.contains('heart') || key.contains('health') || key.contains('medical')) {
      return Icons.favorite_rounded;
    }
    if (key.contains('academic') || key.contains('cap') || key.contains('school') || key.contains('education')) {
      return Icons.school_rounded;
    }
    if (key.contains('briefcase') || key.contains('work')) {
      return Icons.work_rounded;
    }
    if (key.contains('gift') || key.contains('card_giftcard')) {
      return Icons.card_giftcard_rounded;
    }
    if (key.contains('musical-note') || key.contains('music') || key.contains('entertainment')) {
      return Icons.music_note_rounded;
    }
    if (key.contains('banknotes') || key.contains('cash') || key.contains('wallet') || key == 'account_balance_wallet') {
      return Icons.account_balance_wallet_rounded;
    }
    if (key.contains('credit-card') || key.contains('card')) {
      return Icons.credit_card_rounded;
    }
    if (key.contains('chart-bar') || key.contains('trending') || key.contains('investment') || key == 'trending_up') {
      return Icons.trending_up_rounded;
    }
    if (key.contains('receipt') || key.contains('bill')) {
      return Icons.receipt_long_rounded;
    }
    if (key.contains('plane') || key.contains('flight') || key.contains('travel')) {
      return Icons.flight_rounded;
    }
    if (key.contains('game') || key.contains('sports')) {
      return Icons.sports_esports_rounded;
    }

    // 2. Fallback based on category name
    if (nameKey.contains('makan') || nameKey.contains('food') || nameKey.contains('minum') || nameKey.contains('drink') || nameKey.contains('resto')) {
      return Icons.restaurant_rounded;
    }
    if (nameKey.contains('transport') || nameKey.contains('mobil') || nameKey.contains('motor') || nameKey.contains('bensin') || nameKey.contains('ojol') || nameKey.contains('grab') || nameKey.contains('gojek')) {
      return Icons.directions_car_rounded;
    }
    if (nameKey.contains('belanja') || nameKey.contains('shop') || nameKey.contains('mall')) {
      return Icons.shopping_bag_rounded;
    }
    if (nameKey.contains('gaji') || nameKey.contains('salary') || nameKey.contains('wage') || nameKey.contains('pendapatan')) {
      return Icons.payments_rounded;
    }
    if (nameKey.contains('invest') || nameKey.contains('saham') || nameKey.contains('crypto') || nameKey.contains('reksadana') || nameKey.contains('tabungan')) {
      return Icons.trending_up_rounded;
    }
    if (nameKey.contains('tagihan') || nameKey.contains('bill') || nameKey.contains('listrik') || nameKey.contains('air') || nameKey.contains('wifi') || nameKey.contains('utilitas')) {
      return Icons.receipt_long_rounded;
    }
    if (nameKey.contains('hiburan') || nameKey.contains('entertain') || nameKey.contains('nonton') || nameKey.contains('game')) {
      return Icons.sports_esports_rounded;
    }
    if (nameKey.contains('kesehatan') || nameKey.contains('health') || nameKey.contains('obat') || nameKey.contains('dokter')) {
      return Icons.favorite_rounded;
    }
    if (nameKey.contains('pendidikan') || nameKey.contains('kuliah') || nameKey.contains('kursus') || nameKey.contains('buku') || nameKey.contains('sekolah')) {
      return Icons.school_rounded;
    }
    if (nameKey.contains('hadiah') || nameKey.contains('gift') || nameKey.contains('bonus')) {
      return Icons.card_giftcard_rounded;
    }

    return Icons.local_offer_rounded;
  }
}
