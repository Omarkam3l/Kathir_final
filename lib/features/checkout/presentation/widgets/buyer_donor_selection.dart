import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_dimensions.dart';

/// Enum for buyer/donor mode selection
enum PurchaseMode {
  buyer,  // User is buying meals
  donor,  // User is donating meals
}

extension PurchaseModeX on PurchaseMode {
  String get label {
    switch (this) {
      case PurchaseMode.buyer:
        return 'Buy';
      case PurchaseMode.donor:
        return 'Donate';
    }
  }

  String get description {
    switch (this) {
      case PurchaseMode.buyer:
        return 'Purchase meals for yourself';
      case PurchaseMode.donor:
        return 'Donate meals to those in need';
    }
  }

  IconData get icon {
    switch (this) {
      case PurchaseMode.buyer:
        return Icons.shopping_cart;
      case PurchaseMode.donor:
        return Icons.volunteer_activism;
    }
  }
}

/// Widget for selecting buyer or donor mode at checkout
/// Only shown for UserRole.user
class BuyerDonorSelection extends StatelessWidget {
  final PurchaseMode selectedMode;
  final ValueChanged<PurchaseMode> onModeChanged;

  const BuyerDonorSelection({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.primaryAccent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryAccent.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeButton(
              mode: PurchaseMode.buyer,
              isSelected: selectedMode == PurchaseMode.buyer,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            margin: const EdgeInsets.symmetric(vertical: 10),
            color: Colors.white.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _buildModeButton(
              mode: PurchaseMode.donor,
              isSelected: selectedMode == PurchaseMode.donor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required PurchaseMode mode,
    required bool isSelected,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onModeChanged(mode),
        borderRadius: BorderRadius.horizontal(
          left: mode == PurchaseMode.buyer
              ? const Radius.circular(AppDimensions.radiusXLarge)
              : Radius.zero,
          right: mode == PurchaseMode.donor
              ? const Radius.circular(AppDimensions.radiusXLarge)
              : Radius.zero,
        ),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                mode.icon,
                color: Colors.white,
                size: AppDimensions.iconLarge,
              ),
              const SizedBox(height: 4),
              Text(
                mode.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

