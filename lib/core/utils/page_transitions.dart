import 'package:flutter/material.dart';

/// A custom page transition builder that implements a "Push" effect similar to PowerPoint.
/// 
/// When navigating to a new page:
/// - The incoming page slides in from the right.
/// - The outgoing page slides out to the left.
/// 
/// This creates a seamless "push" animation where both pages move together.
class SlidePushPageTransitionsBuilder extends PageTransitionsBuilder {
  const SlidePushPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Animation for the incoming page (entering)
    // Slides from Right (1, 0) to Center (0, 0)
    final entranceTween = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    );
    
    // Animation for the outgoing page (exiting when a new page covers it)
    // Slides from Center (0, 0) to Left (-1, 0)
    final exitTween = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.0, 0.0),
    );

    // Apply curve to both animations
    // Use easeInOut for a smooth "PowerPoint-like" feel
    const curve = Curves.easeInOut;

    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: curve,
    );
    
    final curvedSecondaryAnimation = CurvedAnimation(
      parent: secondaryAnimation,
      curve: curve,
    );

    // If secondaryAnimation is running (we are being covered by a new page),
    // we slide out to the left.
    // If animation is running (we are the new page entering),
    // we slide in from the right.
    
    // Note: SlideTransition combines transform. So if both are active (rare in standard stack, 
    // but effectively we want the 'child' to be affected by both depending on its role).
    // Actually, for a single page widget in the stack:
    // - When it enters: animation 0->1. It slides in. secondaryAnimation is 0.
    // - When it is covered: animation is 1. secondaryAnimation 0->1. It slides out.
    // - When it is revealed (pop): secondaryAnimation 1->0. It slides in from left.
    // - When it is popped: animation 1->0. It slides out to right.
    
    return SlideTransition(
      position: exitTween.animate(curvedSecondaryAnimation),
      child: SlideTransition(
        position: entranceTween.animate(curvedAnimation),
        child: child,
      ),
    );
  }
}
