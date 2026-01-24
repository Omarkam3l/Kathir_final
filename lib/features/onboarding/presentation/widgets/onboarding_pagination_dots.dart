import 'package:flutter/material.dart';
import 'package:kathir_final/core/utils/app_colors.dart';

/// Pagination indicator for onboarding. Active dot is wider; inactive uses grey.
class OnboardingPaginationDots extends StatelessWidget {
  final int pageCount;
  final int currentPage;

  const OnboardingPaginationDots({
    super.key,
    required this.pageCount,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(pageCount, (i) {
        final isActive = i == currentPage;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: isActive ? 32 : 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.grey,
            borderRadius: BorderRadius.circular(4),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}
