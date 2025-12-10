import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/utils/app_dimensions.dart';

/// Header widget for the home screen with search functionality
class HomeHeader extends StatelessWidget {
  final ValueChanged<String> onQueryChanged;

  const HomeHeader({
    super.key,
    required this.onQueryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
            child: Text(
            'Find your',
            style: TextStyle(
              fontSize: 20,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
            child: Row(
              children: [
                Text(
                  'Best Food',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'here',
                  style: TextStyle(
                    fontSize: 26,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          SizedBox(
            height: AppDimensions.searchBarHeight,
            child: Stack(
              children: [
                Container(
                  height: AppDimensions.searchBarHeight,
                  decoration: BoxDecoration(
                    color: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                  ),
                  padding: const EdgeInsets.only(
                    left: AppDimensions.radiusLarge,
                    right: 68,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Theme.of(context).iconTheme.color),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          onChanged: onQueryChanged,
                          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                          decoration: const InputDecoration(
                            hintText: 'Search food...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            isCollapsed: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed('/search');
                    },
                    child: Transform.rotate(
                      angle: 45 * pi / 180,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            )
                          ],
                        ),
                        child: Transform.rotate(
                          angle: -45 * pi / 180,
                          child: const Icon(Icons.tune, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }
