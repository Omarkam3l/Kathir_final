import 'package:flutter/material.dart';

/// Loading indicator with three animated dots
class LoadingIndicatorWidget extends StatefulWidget {
  const LoadingIndicatorWidget({super.key});

  @override
  State<LoadingIndicatorWidget> createState() => _LoadingIndicatorWidgetState();
}

class _LoadingIndicatorWidgetState extends State<LoadingIndicatorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFf8fafc),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDot(0),
          const SizedBox(width: 8),
          _buildDot(1),
          const SizedBox(width: 8),
          _buildDot(2),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final delay = index * 0.16;
        final value = (_controller.value - delay) % 1.0;
        final scale = value < 0.4 ? value / 0.4 : (1.0 - value) / 0.6;
        
        return Transform.scale(
          scale: scale.clamp(0.0, 1.0),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF64748b),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
