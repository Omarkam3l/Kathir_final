import 'package:flutter/material.dart';

/// Custom clipper for diamond-shaped widgets
class DiamondClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final halfWidth = size.width / 2;
    final halfHeight = size.height / 2;

    path.moveTo(halfWidth, 0); // Top
    path.lineTo(size.width, halfHeight); // Right
    path.lineTo(halfWidth, size.height); // Bottom
    path.lineTo(0, halfHeight); // Left
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

