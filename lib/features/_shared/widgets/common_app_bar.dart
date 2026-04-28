import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/app_colors.dart';

/// ⭐ Common App Bar for all bottom navigation screens (except Home)
/// Glass effect with title on left, chatbot & notifications on right
class CommonAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;

  const CommonAppBar({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.glassCardBg, // شفاف
        border: Border(
          bottom: BorderSide(
            color: AppColors.glassCardBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Title on the left
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                    letterSpacing: -0.5,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Icons on the right
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Kathir Agent AI button (Chatbot)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push('/kathir-agent'),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.smart_toy,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Notification button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.go('/profile/notifications'),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.glassCardBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.glassCardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Center(
                          child: Icon(
                            Icons.notifications_outlined,
                            size: 22,
                            color: AppColors.textMain,
                          ),
                        ),
                        // Red badge dot
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
