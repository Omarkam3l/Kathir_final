import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../user_home/domain/entities/meal_offer.dart';
import '../../../user_home/domain/entities/restaurant.dart';

class NotificationsScreenNew extends StatefulWidget {
  const NotificationsScreenNew({super.key});

  @override
  State<NotificationsScreenNew> createState() => _NotificationsScreenNewState();
}

class _NotificationsScreenNewState extends State<NotificationsScreenNew> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<NotificationItem> _notifications = [];
  List<FreeMealNotification> _freeMealNotifications = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      // Load FREE MEAL notifications (special)
      final freeMealResponse = await _supabase.rpc(
        'get_free_meal_notifications',
        params: {'p_user_id': userId, 'p_limit': 50},
      );

      final freeMealNotifs = (freeMealResponse as List).map((json) {
        return FreeMealNotification(
          id: json['id'],
          mealId: json['meal_id'],
          mealTitle: json['meal_title'] ?? 'Free Meal',
          mealImageUrl: json['meal_image_url'] ?? '',
          mealCategory: json['meal_category'] ?? '',
          mealQuantity: json['meal_quantity'] ?? 0,
          restaurantId: json['restaurant_id'],
          restaurantName: json['restaurant_name'] ?? 'Restaurant',
          restaurantLogo: json['restaurant_logo'] ?? '',
          sentAt: DateTime.parse(json['sent_at']),
          isRead: json['is_read'] ?? false,
          claimed: json['claimed'] ?? false,
          claimedAt: json['claimed_at'] != null ? DateTime.parse(json['claimed_at']) : null,
        );
      }).toList();

      // Load regular category notifications
      final response = await _supabase
          .from('category_notifications')
          .select('''
            *,
            meals:meal_id (
              id,
              title,
              image_url,
              discounted_price,
              original_price,
              quantity_available,
              expiry_date,
              category,
              location,
              restaurant_id,
              restaurants:restaurant_id (
                restaurant_name,
                rating,
                profile_id
              )
            )
          ''')
          .eq('user_id', userId)
          .order('sent_at', ascending: false)
          .limit(50);

      final notifications = (response as List).map((json) {
        final mealData = json['meals'];
        final restaurantData = mealData?['restaurants'];
        
        return NotificationItem(
          id: json['id'],
          category: json['category'],
          sentAt: DateTime.parse(json['sent_at']),
          isRead: json['is_read'],
          meal: mealData != null ? MealOffer(
            id: mealData['id'],
            title: mealData['title'] ?? 'New Meal',
            location: mealData['location'] ?? 'Cairo, Egypt',
            imageUrl: mealData['image_url'] ?? '',
            originalPrice: (mealData['original_price'] as num?)?.toDouble() ?? 0.0,
            donationPrice: (mealData['discounted_price'] as num?)?.toDouble() ?? 0.0,
            quantity: mealData['quantity_available'] ?? 0,
            expiry: DateTime.parse(mealData['expiry_date']),
            restaurant: Restaurant(
              id: restaurantData?['profile_id'] ?? '',
              name: restaurantData?['restaurant_name'] ?? 'Restaurant',
              rating: (restaurantData?['rating'] as num?)?.toDouble() ?? 0.0,
            ),
          ) : null,
        );
      }).toList();

      setState(() {
        _freeMealNotifications = freeMealNotifs;
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('category_notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
        }
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _markFreeMealAsRead(String notificationId) async {
    try {
      await _supabase
          .from('free_meal_user_notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      setState(() {
        final index = _freeMealNotifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _freeMealNotifications[index] = _freeMealNotifications[index].copyWith(isRead: true);
        }
      });
    } catch (e) {
      debugPrint('Error marking free meal notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Mark regular notifications as read
      await _supabase
          .from('category_notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);

      // Mark free meal notifications as read
      await _supabase
          .from('free_meal_user_notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);

      setState(() {
        _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
        _freeMealNotifications = _freeMealNotifications.map((n) => n.copyWith(isRead: true)).toList();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textMain = isDark ? Colors.white : const Color(0xFF111827);
    final textSub = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    final unreadCount = _notifications.where((n) => !n.isRead).length + 
                        _freeMealNotifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      context.go('/home');
                    },
                    icon: const Icon(Icons.arrow_back_ios, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textMain,
                          ),
                        ),
                        if (unreadCount > 0)
                          Text(
                            '$unreadCount unread',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (unreadCount > 0)
                    TextButton(
                      onPressed: _markAllAsRead,
                      child: Text(
                        'Mark all read',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 64, color: textSub),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading notifications',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  color: textSub,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _loadNotifications,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _notifications.isEmpty && _freeMealNotifications.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.notifications_none, size: 64, color: textSub),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No notifications yet',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: textMain,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Subscribe to meal categories in Favorites\nto get notified about new meals',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      color: textSub,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadNotifications,
                              color: AppColors.primary,
                              child: ListView(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                children: [
                                  // FREE MEALS SECTION
                                  if (_freeMealNotifications.isNotEmpty) ...[
                                    _buildSectionHeader('🎁 FREE MEALS', _freeMealNotifications.length, isDark, textMain),
                                    const SizedBox(height: 12),
                                    ..._freeMealNotifications.map((notification) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _buildFreeMealCard(context, notification, isDark, textMain, textSub),
                                    )),
                                    const SizedBox(height: 8),
                                  ],
                                  
                                  // CATEGORY NOTIFICATIONS SECTION
                                  if (_notifications.isNotEmpty) ...[
                                    _buildSectionHeader('📬 CATEGORY UPDATES', _notifications.length, isDark, textMain),
                                    const SizedBox(height: 12),
                                    ..._notifications.map((notification) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _buildNotificationCard(context, notification, isDark, textMain, textSub),
                                    )),
                                  ],
                                ],
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, bool isDark, Color textMain) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textMain,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFreeMealCard(
    BuildContext context,
    FreeMealNotification notification,
    bool isDark,
    Color textMain,
    Color textSub,
  ) {
    final timeAgo = _getTimeAgo(notification.sentAt);
    final quantityColor = notification.mealQuantity <= 1
        ? Colors.red
        : notification.mealQuantity <= 4
            ? Colors.orange
            : AppColors.primaryGreen;

    return GestureDetector(
      onTap: () async {
        if (!notification.isRead) {
          await _markFreeMealAsRead(notification.id);
        }
        if (context.mounted) {
          // Fetch full meal data before navigating
          try {
            final mealResponse = await _supabase
                .from('meals')
                .select('''
                  *,
                  restaurants:restaurant_id (
                    restaurant_name,
                    rating,
                    profile_id
                  )
                ''')
                .eq('id', notification.mealId)
                .single();

            final restaurantData = mealResponse['restaurants'];
            final mealOffer = MealOffer(
              id: mealResponse['id'],
              title: mealResponse['title'] ?? 'Free Meal',
              location: mealResponse['location'] ?? 'Cairo, Egypt',
              imageUrl: mealResponse['image_url'] ?? '',
              originalPrice: (mealResponse['original_price'] as num?)?.toDouble() ?? 0.0,
              donationPrice: (mealResponse['discounted_price'] as num?)?.toDouble() ?? 0.0,
              quantity: mealResponse['quantity_available'] ?? 0,
              expiry: DateTime.parse(mealResponse['expiry_date']),
              restaurant: Restaurant(
                id: restaurantData?['profile_id'] ?? '',
                name: restaurantData?['restaurant_name'] ?? 'Restaurant',
                rating: (restaurantData?['rating'] as num?)?.toDouble() ?? 0.0,
              ),
            );

            if (context.mounted) {
              context.push('/meal/${notification.mealId}', extra: mealOffer);
            }
          } catch (e) {
            debugPrint('Error fetching meal data: $e');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error loading meal details')),
              );
            }
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryGreen.withValues(alpha: 0.1),
              AppColors.primaryGreen.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? AppColors.primaryGreen.withValues(alpha: 0.3)
                : AppColors.primaryGreen,
            width: notification.isRead ? 1 : 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with FREE badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: notification.mealImageUrl.isNotEmpty
                      ? Image.network(
                          notification.mealImageUrl,
                          width: double.infinity,
                          height: 140,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 140,
                            color: AppColors.primaryGreen.withValues(alpha: 0.2),
                            child: const Icon(Icons.restaurant, size: 48, color: AppColors.primaryGreen),
                          ),
                        )
                      : Container(
                          height: 140,
                          color: AppColors.primaryGreen.withValues(alpha: 0.2),
                          child: const Icon(Icons.restaurant, size: 48, color: AppColors.primaryGreen),
                        ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.volunteer_activism, size: 16, color: Colors.black),
                        const SizedBox(width: 4),
                        Text(
                          'FREE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.card_giftcard, size: 20, color: AppColors.primaryGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          notification.mealTitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textMain,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (notification.restaurantLogo.isNotEmpty)
                        ClipOval(
                          child: Image.network(
                            notification.restaurantLogo,
                            width: 20,
                            height: 20,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.restaurant, size: 20),
                          ),
                        )
                      else
                        const Icon(Icons.restaurant, size: 20),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'From ${notification.restaurantName}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: textSub,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: textSub,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: quantityColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_2, size: 14, color: quantityColor),
                            const SizedBox(width: 4),
                            Text(
                              notification.mealQuantity <= 1
                                  ? 'Last one!'
                                  : 'Only ${notification.mealQuantity} left',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: quantityColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () async {
                          if (!notification.isRead) {
                            await _markFreeMealAsRead(notification.id);
                          }
                          if (context.mounted) {
                            // Fetch full meal data before navigating
                            try {
                              final mealResponse = await _supabase
                                  .from('meals')
                                  .select('''
                                    *,
                                    restaurants:restaurant_id (
                                      restaurant_name,
                                      rating,
                                      profile_id
                                    )
                                  ''')
                                  .eq('id', notification.mealId)
                                  .single();

                              final restaurantData = mealResponse['restaurants'];
                              final mealOffer = MealOffer(
                                id: mealResponse['id'],
                                title: mealResponse['title'] ?? 'Free Meal',
                                location: mealResponse['location'] ?? 'Cairo, Egypt',
                                imageUrl: mealResponse['image_url'] ?? '',
                                originalPrice: (mealResponse['original_price'] as num?)?.toDouble() ?? 0.0,
                                donationPrice: (mealResponse['discounted_price'] as num?)?.toDouble() ?? 0.0,
                                quantity: mealResponse['quantity_available'] ?? 0,
                                expiry: DateTime.parse(mealResponse['expiry_date']),
                                restaurant: Restaurant(
                                  id: restaurantData?['profile_id'] ?? '',
                                  name: restaurantData?['restaurant_name'] ?? 'Restaurant',
                                  rating: (restaurantData?['rating'] as num?)?.toDouble() ?? 0.0,
                                ),
                              );

                              if (context.mounted) {
                                context.push('/meal/${notification.mealId}', extra: mealOffer);
                              }
                            } catch (e) {
                              debugPrint('Error fetching meal data: $e');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Error loading meal details')),
                                );
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Claim Now',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationItem notification,
    bool isDark,
    Color textMain,
    Color textSub,
  ) {
    final cardBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    
    final timeAgo = _getTimeAgo(notification.sentAt);
    final meal = notification.meal;

    return GestureDetector(
      onTap: () async {
        if (!notification.isRead) {
          await _markAsRead(notification.id);
        }
        if (meal != null && context.mounted) {
          context.push('/meal/${meal.id}', extra: meal);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isRead ? borderColor : AppColors.primary,
            width: notification.isRead ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: notification.isRead
                    ? Colors.grey.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notification.isRead ? Icons.notifications_none : Icons.notifications_active,
                color: notification.isRead ? Colors.grey : AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'New ${notification.category} Available!',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textMain,
                          ),
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: textSub,
                        ),
                      ),
                    ],
                  ),
                  if (meal != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      meal.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${meal.restaurant.name} • EGP ${meal.donationPrice.toStringAsFixed(0)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: textSub,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Meal Image (if available)
            if (meal != null && meal.imageUrl.isNotEmpty) ...[
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 60,
                  height: 60,
                  color: AppColors.primary.withValues(alpha: 0.1),
                  child: Image.network(
                    meal.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.restaurant,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}

class NotificationItem {
  final String id;
  final String category;
  final DateTime sentAt;
  final bool isRead;
  final MealOffer? meal;

  NotificationItem({
    required this.id,
    required this.category,
    required this.sentAt,
    required this.isRead,
    this.meal,
  });

  NotificationItem copyWith({
    String? id,
    String? category,
    DateTime? sentAt,
    bool? isRead,
    MealOffer? meal,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      category: category ?? this.category,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
      meal: meal ?? this.meal,
    );
  }
}

class FreeMealNotification {
  final String id;
  final String mealId;
  final String mealTitle;
  final String mealImageUrl;
  final String mealCategory;
  final int mealQuantity;
  final String restaurantId;
  final String restaurantName;
  final String restaurantLogo;
  final DateTime sentAt;
  final bool isRead;
  final bool claimed;
  final DateTime? claimedAt;

  FreeMealNotification({
    required this.id,
    required this.mealId,
    required this.mealTitle,
    required this.mealImageUrl,
    required this.mealCategory,
    required this.mealQuantity,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantLogo,
    required this.sentAt,
    required this.isRead,
    required this.claimed,
    this.claimedAt,
  });

  FreeMealNotification copyWith({
    String? id,
    String? mealId,
    String? mealTitle,
    String? mealImageUrl,
    String? mealCategory,
    int? mealQuantity,
    String? restaurantId,
    String? restaurantName,
    String? restaurantLogo,
    DateTime? sentAt,
    bool? isRead,
    bool? claimed,
    DateTime? claimedAt,
  }) {
    return FreeMealNotification(
      id: id ?? this.id,
      mealId: mealId ?? this.mealId,
      mealTitle: mealTitle ?? this.mealTitle,
      mealImageUrl: mealImageUrl ?? this.mealImageUrl,
      mealCategory: mealCategory ?? this.mealCategory,
      mealQuantity: mealQuantity ?? this.mealQuantity,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantLogo: restaurantLogo ?? this.restaurantLogo,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
      claimed: claimed ?? this.claimed,
      claimedAt: claimedAt ?? this.claimedAt,
    );
  }
}
