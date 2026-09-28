import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:f_tracker_mobile/core/utils/category_icon_helper.dart';

void main() {
  group('CategoryIconHelper Tests', () {
    test('Maps frontend heroicons to matching Flutter icons', () {
      expect(CategoryIconHelper.getIconData('i-heroicons-shopping-cart'), Icons.shopping_cart_rounded);
      expect(CategoryIconHelper.getIconData('i-heroicons-truck'), Icons.directions_car_rounded);
      expect(CategoryIconHelper.getIconData('i-heroicons-home'), Icons.home_rounded);
      expect(CategoryIconHelper.getIconData('i-heroicons-heart'), Icons.favorite_rounded);
      expect(CategoryIconHelper.getIconData('i-heroicons-academic-cap'), Icons.school_rounded);
      expect(CategoryIconHelper.getIconData('i-heroicons-briefcase'), Icons.work_rounded);
      expect(CategoryIconHelper.getIconData('i-heroicons-gift'), Icons.card_giftcard_rounded);
      expect(CategoryIconHelper.getIconData('i-heroicons-musical-note'), Icons.music_note_rounded);
      expect(CategoryIconHelper.getIconData('i-heroicons-banknotes'), Icons.account_balance_wallet_rounded);
      expect(CategoryIconHelper.getIconData('i-heroicons-chart-bar'), Icons.trending_up_rounded);
    });

    test('Maps backend keywords to matching Flutter icons', () {
      expect(CategoryIconHelper.getIconData('fastfood'), Icons.restaurant_rounded);
      expect(CategoryIconHelper.getIconData('directions_car'), Icons.directions_car_rounded);
      expect(CategoryIconHelper.getIconData('shopping_bag'), Icons.shopping_cart_rounded);
      expect(CategoryIconHelper.getIconData('receipt_long'), Icons.receipt_long_rounded);
      expect(CategoryIconHelper.getIconData('account_balance_wallet'), Icons.account_balance_wallet_rounded);
    });

    test('Falls back to category name keywords when icon is missing or generic tag', () {
      expect(CategoryIconHelper.getIconData('tag', 'Makanan & Minuman'), Icons.restaurant_rounded);
      expect(CategoryIconHelper.getIconData(null, 'Transportasi Bensin'), Icons.directions_car_rounded);
      expect(CategoryIconHelper.getIconData('', 'Gaji Bulanan'), Icons.payments_rounded);
      expect(CategoryIconHelper.getIconData('tag', 'Investasi Saham'), Icons.trending_up_rounded);
      expect(CategoryIconHelper.getIconData(null, 'Tagihan Listrik'), Icons.receipt_long_rounded);
    });

    test('availableIcons contains standard set for category creation', () {
      expect(CategoryIconHelper.availableIcons.length, greaterThanOrEqualTo(12));
    });
  });
}
