import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/utils/app_colors.dart';

class GrowingTreeWidget extends StatefulWidget {
  final int donationCount;
  final VoidCallback? onTap;
  
  const GrowingTreeWidget({
    super.key,
    required this.donationCount,
    this.onTap,
  });

  @override
  State<GrowingTreeWidget> createState() => _GrowingTreeWidgetState();
}

class _GrowingTreeWidgetState extends State<GrowingTreeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _growthAnimation;
  int _previousDonationCount = 0;

  @override
  void initState() {
    super.initState();
    _previousDonationCount = widget.donationCount;
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _growthAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
  }

  @override
  void didUpdateWidget(GrowingTreeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Trigger animation when donation count increases
    if (widget.donationCount > _previousDonationCount) {
      _controller.forward(from: 0.0);
      _previousDonationCount = widget.donationCount;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Calculate tree growth stage based on donations
  TreeGrowthStage _getGrowthStage() {
    if (widget.donationCount == 0) return TreeGrowthStage.seed;
    if (widget.donationCount == 1) return TreeGrowthStage.sprout;
    if (widget.donationCount == 2) return TreeGrowthStage.sapling;
    if (widget.donationCount == 3) return TreeGrowthStage.youngTree;
    if (widget.donationCount == 4) return TreeGrowthStage.matureTree;
    return TreeGrowthStage.fullTree; // 5+ donations
  }

  @override
  Widget build(BuildContext context) {
    final stage = _getGrowthStage();
    
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.1),
              AppColors.primary.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.eco, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Your Impact Tree',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Tree Animation
            AnimatedBuilder(
              animation: _growthAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_growthAnimation.value * 0.1),
                  child: CustomPaint(
                    size: const Size(200, 200),
                    painter: TreePainter(
                      stage: stage,
                      donationCount: widget.donationCount,
                      animationValue: _growthAnimation.value,
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 20),
            
            // Stage Info
            Column(
              children: [
                Text(
                  _getStageName(stage),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.donationCount} ${widget.donationCount == 1 ? 'donation' : 'donations'} made',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStageMessage(stage, widget.donationCount),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStageName(TreeGrowthStage stage) {
    switch (stage) {
      case TreeGrowthStage.seed:
        return '🌱 Seed';
      case TreeGrowthStage.sprout:
        return '🌱 Sprout';
      case TreeGrowthStage.sapling:
        return '🌿 Sapling';
      case TreeGrowthStage.youngTree:
        return '🌳 Young Tree';
      case TreeGrowthStage.matureTree:
        return '🌳 Mature Tree';
      case TreeGrowthStage.fullTree:
        return '🌳 Mighty Oak';
    }
  }

  String _getStageMessage(TreeGrowthStage stage, int count) {
    switch (stage) {
      case TreeGrowthStage.seed:
        return 'Make your first donation to plant your tree!';
      case TreeGrowthStage.sprout:
        return '1 more donation to become a sapling';
      case TreeGrowthStage.sapling:
        return '1 more donation to grow into a young tree';
      case TreeGrowthStage.youngTree:
        return '1 more donation to become mature';
      case TreeGrowthStage.matureTree:
        return '1 more donation to reach full growth';
      case TreeGrowthStage.fullTree:
        return 'Your tree is fully grown! Keep making an impact!';
    }
  }
}

enum TreeGrowthStage {
  seed,
  sprout,
  sapling,
  youngTree,
  matureTree,
  fullTree,
}

class TreePainter extends CustomPainter {
  final TreeGrowthStage stage;
  final int donationCount;
  final double animationValue;

  TreePainter({
    required this.stage,
    required this.donationCount,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    switch (stage) {
      case TreeGrowthStage.seed:
        _drawSeed(canvas, center);
        break;
      case TreeGrowthStage.sprout:
        _drawSprout(canvas, center, size);
        break;
      case TreeGrowthStage.sapling:
        _drawSapling(canvas, center, size);
        break;
      case TreeGrowthStage.youngTree:
        _drawYoungTree(canvas, center, size);
        break;
      case TreeGrowthStage.matureTree:
        _drawMatureTree(canvas, center, size);
        break;
      case TreeGrowthStage.fullTree:
        _drawFullTree(canvas, center, size);
        break;
    }
  }

  void _drawSeed(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = const Color(0xFF8B4513)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 15, paint);
    
    // Highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center.translate(-5, -5), 5, highlightPaint);
  }

  void _drawSprout(Canvas canvas, Offset center, Size size) {
    // Ground
    _drawGround(canvas, center, size);
    
    // Stem
    final stemPaint = Paint()
      ..color = const Color(0xFF228B22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final stemPath = Path();
    stemPath.moveTo(center.dx, center.dy + 20);
    stemPath.lineTo(center.dx, center.dy - 20);
    canvas.drawPath(stemPath, stemPaint);

    // Small leaves
    final leafPaint = Paint()
      ..color = const Color(0xFF32CD32)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center.translate(-10, -15), 8, leafPaint);
    canvas.drawCircle(center.translate(10, -20), 8, leafPaint);
  }

  void _drawSapling(Canvas canvas, Offset center, Size size) {
    // Ground
    _drawGround(canvas, center, size);
    
    // Trunk
    final trunkPaint = Paint()
      ..color = const Color(0xFF8B4513)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx, center.dy + 30),
      Offset(center.dx, center.dy - 30),
      trunkPaint,
    );

    // Leaves
    final leafPaint = Paint()
      ..color = const Color(0xFF228B22)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center.translate(0, -40), 25, leafPaint);
    canvas.drawCircle(center.translate(-15, -30), 20, leafPaint);
    canvas.drawCircle(center.translate(15, -30), 20, leafPaint);
  }

  void _drawYoungTree(Canvas canvas, Offset center, Size size) {
    // Ground
    _drawGround(canvas, center, size);
    
    // Trunk
    final trunkPaint = Paint()
      ..color = const Color(0xFF8B4513)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx, center.dy + 40),
      Offset(center.dx, center.dy - 20),
      trunkPaint,
    );

    // Branches
    final branchPaint = Paint()
      ..color = const Color(0xFF8B4513)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx, center.dy - 10),
      Offset(center.dx - 25, center.dy - 25),
      branchPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 10),
      Offset(center.dx + 25, center.dy - 25),
      branchPaint,
    );

    // Foliage
    final foliagePaint = Paint()
      ..color = const Color(0xFF228B22)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center.translate(0, -50), 35, foliagePaint);
    canvas.drawCircle(center.translate(-30, -35), 25, foliagePaint);
    canvas.drawCircle(center.translate(30, -35), 25, foliagePaint);
    canvas.drawCircle(center.translate(-20, -20), 20, foliagePaint);
    canvas.drawCircle(center.translate(20, -20), 20, foliagePaint);
  }

  void _drawMatureTree(Canvas canvas, Offset center, Size size) {
    // Ground
    _drawGround(canvas, center, size);
    
    // Trunk
    final trunkPaint = Paint()
      ..color = const Color(0xFF8B4513)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx, center.dy + 50),
      Offset(center.dx, center.dy - 30),
      trunkPaint,
    );

    // Multiple branches
    final branchPaint = Paint()
      ..color = const Color(0xFF8B4513)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    // Left branches
    canvas.drawLine(Offset(center.dx, center.dy - 20), Offset(center.dx - 35, center.dy - 40), branchPaint);
    canvas.drawLine(Offset(center.dx, center.dy - 10), Offset(center.dx - 30, center.dy - 25), branchPaint);
    
    // Right branches
    canvas.drawLine(Offset(center.dx, center.dy - 20), Offset(center.dx + 35, center.dy - 40), branchPaint);
    canvas.drawLine(Offset(center.dx, center.dy - 10), Offset(center.dx + 30, center.dy - 25), branchPaint);

    // Dense foliage
    final foliagePaint = Paint()
      ..color = const Color(0xFF228B22)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center.translate(0, -60), 40, foliagePaint);
    canvas.drawCircle(center.translate(-35, -50), 30, foliagePaint);
    canvas.drawCircle(center.translate(35, -50), 30, foliagePaint);
    canvas.drawCircle(center.translate(-25, -30), 25, foliagePaint);
    canvas.drawCircle(center.translate(25, -30), 25, foliagePaint);
    canvas.drawCircle(center.translate(0, -35), 30, foliagePaint);
  }

  void _drawFullTree(Canvas canvas, Offset center, Size size) {
    // Ground with grass
    _drawGround(canvas, center, size);
    
    // Thick trunk
    final trunkPaint = Paint()
      ..color = const Color(0xFF8B4513)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx, center.dy + 60),
      Offset(center.dx, center.dy - 40),
      trunkPaint,
    );

    // Many branches
    final branchPaint = Paint()
      ..color = const Color(0xFF8B4513)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    // Complex branch structure
    canvas.drawLine(Offset(center.dx, center.dy - 30), Offset(center.dx - 40, center.dy - 55), branchPaint);
    canvas.drawLine(Offset(center.dx, center.dy - 30), Offset(center.dx + 40, center.dy - 55), branchPaint);
    canvas.drawLine(Offset(center.dx, center.dy - 20), Offset(center.dx - 35, center.dy - 35), branchPaint);
    canvas.drawLine(Offset(center.dx, center.dy - 20), Offset(center.dx + 35, center.dy - 35), branchPaint);
    canvas.drawLine(Offset(center.dx, center.dy - 10), Offset(center.dx - 30, center.dy - 20), branchPaint);
    canvas.drawLine(Offset(center.dx, center.dy - 10), Offset(center.dx + 30, center.dy - 20), branchPaint);

    // Very dense foliage
    final foliagePaint = Paint()
      ..color = const Color(0xFF228B22)
      ..style = PaintingStyle.fill;

    // Top layer
    canvas.drawCircle(center.translate(0, -70), 45, foliagePaint);
    canvas.drawCircle(center.translate(-40, -65), 35, foliagePaint);
    canvas.drawCircle(center.translate(40, -65), 35, foliagePaint);
    
    // Middle layer
    canvas.drawCircle(center.translate(-50, -45), 30, foliagePaint);
    canvas.drawCircle(center.translate(50, -45), 30, foliagePaint);
    canvas.drawCircle(center.translate(0, -45), 35, foliagePaint);
    
    // Bottom layer
    canvas.drawCircle(center.translate(-35, -25), 28, foliagePaint);
    canvas.drawCircle(center.translate(35, -25), 28, foliagePaint);
    canvas.drawCircle(center.translate(0, -20), 30, foliagePaint);

    // Add some fruits/flowers
    final fruitPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final angle = (i * math.pi * 2 / 5) + animationValue;
      final x = center.dx + math.cos(angle) * 40;
      final y = center.dy - 50 + math.sin(angle) * 20;
      canvas.drawCircle(Offset(x, y), 4, fruitPaint);
    }
  }

  void _drawGround(Canvas canvas, Offset center, Size size) {
    final groundPaint = Paint()
      ..color = const Color(0xFF8B7355)
      ..style = PaintingStyle.fill;

    final groundRect = Rect.fromLTWH(
      0,
      center.dy + 20,
      size.width,
      size.height - (center.dy + 20),
    );
    canvas.drawRect(groundRect, groundPaint);

    // Grass
    final grassPaint = Paint()
      ..color = const Color(0xFF90EE90)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (double x = 10; x < size.width; x += 15) {
      canvas.drawLine(
        Offset(x, center.dy + 20),
        Offset(x, center.dy + 30),
        grassPaint,
      );
    }
  }

  @override
  bool shouldRepaint(TreePainter oldDelegate) {
    return oldDelegate.stage != stage ||
        oldDelegate.donationCount != donationCount ||
        oldDelegate.animationValue != animationValue;
  }
}
