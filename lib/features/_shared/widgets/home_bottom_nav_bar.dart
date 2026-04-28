import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kathir_final/core/utils/app_colors.dart';

/// Animated glassmorphism bottom nav bar
/// The selected circle slides from one icon to another
class HomeBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const HomeBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  @override
  State<HomeBottomNavBar> createState() => _HomeBottomNavBarState();
}

class _HomeBottomNavBarState extends State<HomeBottomNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnim;

  // 5 items → positions 0..4
  static const int _itemCount = 5;
  late double _fromIndex;
  late double _toIndex;

  @override
  void initState() {
    super.initState();
    _fromIndex = widget.currentIndex.toDouble();
    _toIndex   = widget.currentIndex.toDouble();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _slideAnim = Tween<double>(begin: _fromIndex, end: _toIndex)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic));
  }

  @override
  void didUpdateWidget(HomeBottomNavBar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _fromIndex = _slideAnim.value; // start from current animated position
      _toIndex   = widget.currentIndex.toDouble();

      _slideAnim = Tween<double>(begin: _fromIndex, end: _toIndex)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic));

      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding > 0 ? bottomPadding : 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 62,
            decoration: BoxDecoration(
              color: AppColors.glassCardBg, // ← استخدام اللون من AppColors
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: AppColors.glassCardBorder, // ← استخدام اللون من AppColors
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05), // ← ظل خفيف جداً
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / _itemCount;

                return AnimatedBuilder(
                  animation: _slideAnim,
                  builder: (context, _) {
                    // Circle x position (center of animated slot)
                    final circleX = itemWidth * _slideAnim.value + itemWidth / 2;

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // ── Sliding circle ──────────────────────────────
                        Positioned(
                          left: circleX - 23, // 23 = half of 46
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ── Icons row ────────────────────────────────────
                        Row(
                          children: [
                            _buildItem(0, Icons.favorite_border_rounded, Icons.favorite_rounded,      itemWidth),
                            _buildItem(1, Icons.shopping_cart_outlined,  Icons.shopping_cart_rounded, itemWidth),
                            _buildItem(2, Icons.home_outlined,           Icons.home_rounded,          itemWidth),
                            _buildItem(3, Icons.receipt_long_outlined,   Icons.receipt_long_rounded,  itemWidth),
                            _buildItem(4, Icons.person_outline_rounded,  Icons.person_rounded,        itemWidth),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(int idx, IconData icon, IconData activeIcon, double width) {
    final selected = widget.currentIndex == idx;
    return GestureDetector(
      onTap: () => widget.onTap?.call(idx),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        height: 62,
        child: Center(
          child: Icon(
            selected ? activeIcon : icon,
            size: 22,
            color: selected ? Colors.white : const Color.fromARGB(255, 41, 39, 39),
          ),
        ),
      ),
    );
  }
}
