import 'package:flutter/material.dart';

enum UserRole {
  user,
  ngo,
  restaurant,
  admin;

  String get displayName {
    return switch (this) {
      UserRole.user => 'User',
      UserRole.ngo => 'Organization',
      UserRole.restaurant => 'Restaurant / Hotel',
      UserRole.admin => 'Admin',
    };
  }

  String get wireValue {
    return switch (this) {
      UserRole.user => 'user',
      UserRole.ngo => 'ngo',
      UserRole.restaurant => 'restaurant',  // Fixed: was 'rest', now 'restaurant'
      UserRole.admin => 'admin',
    };
  }

  IconData get icon {
    return switch (this) {
      UserRole.user => Icons.person,
      UserRole.ngo => Icons.handshake,
      UserRole.restaurant => Icons.restaurant_menu,
      UserRole.admin => Icons.admin_panel_settings,
    };
  }
}
