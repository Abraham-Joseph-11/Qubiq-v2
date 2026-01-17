import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:little_emmi/Models/flow_block_model.dart';
import 'dart:math' as math; // Import math for pi

/// A widget that renders a single flowchart block based on its type.
class FlowchartShapeWidget extends StatelessWidget {
  final FlowBlock block;
  final bool isSelected;

  const FlowchartShapeWidget({
    super.key,
    required this.block,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    // Define a base text style
    final textStyle = GoogleFonts.poppins(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: 14,
    );

    // Define a standard box shadow
    final boxShadow = [
      BoxShadow(
        color: Colors.black.withOpacity(0.4),
        blurRadius: 8,
        offset: const Offset(0, 4),
      )
    ];

    // Define a border for highlighting when selected
    BoxBorder? border = isSelected
        ? Border.all(color: Colors.yellowAccent.shade400, width: 3)
        : Border.all(color: Colors.white.withOpacity(0.3), width: 1.5);

    Widget child = Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          block.content,
          textAlign: TextAlign.center,
          style: textStyle,
        ),
      ),
    );

    // Use a switch to determine the shape and color
    switch (block.type) {
      case FlowchartBlockType.start:
      case FlowchartBlockType.end:
        return _buildStadium(child, Colors.red.shade400, border, boxShadow);
      case FlowchartBlockType.process:
        return _buildRectangle(child, Colors.blue.shade400, border, boxShadow);
      case FlowchartBlockType.decision:
      // Use the new _buildDiamond method
        return _buildDiamond(child, Colors.green.shade400, border, boxShadow);
      case FlowchartBlockType.input:
      case FlowchartBlockType.output:
      // Use the new _buildParallelogram method
        return _buildParallelogram(
            child, Colors.orange.shade400, border, boxShadow);
    }
  }

  // Common container properties
  BoxDecoration _baseDecoration(Color color, BoxBorder? border) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color,
          _darken(color, 0.2),
        ],
      ),
      border: border,
    );
  }

  // Helper to darken a color
  Color _darken(Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  // Oval/Stadium shape for Start/End (Unchanged)
  Widget _buildStadium(
      Widget child, Color color, BoxBorder? border, List<BoxShadow> shadow) {
    return Container(
      width: block.size.width,
      height: block.size.height,
      decoration: _baseDecoration(color, border).copyWith(
        borderRadius: BorderRadius.circular(block.size.height / 2),
        boxShadow: shadow,
      ),
      child: child,
    );
  }

  // Rectangle shape for Process (Unchanged)
  Widget _buildRectangle(
      Widget child, Color color, BoxBorder? border, List<BoxShadow> shadow) {
    return Container(
      width: block.size.width,
      height: block.size.height,
      decoration: _baseDecoration(color, border).copyWith(
        borderRadius: BorderRadius.circular(12),
        boxShadow: shadow,
      ),
      child: child,
    );
  }

  // vvv --- REPLACED _buildDiamond --- vvv
  /// Diamond shape for Decision, built with ClipPath for correct alignment.
  Widget _buildDiamond(
      Widget child, Color color, BoxBorder? border, List<BoxShadow> shadow) {
    return Container(
      width: block.size.width,
      height: block.size.height,
      child: ClipPath(
        clipper: _DiamondClipper(),
        child: Container(
          decoration: _baseDecoration(color, border).copyWith(
            boxShadow: shadow,
          ),
          child: child, // The text is now correctly centered
        ),
      ),
    );
  }
  // ^^^ --- END OF REPLACEMENT --- ^^^

  // vvv --- REPLACED _buildParallelogram --- vvv
  /// Parallelogram for Input/Output, built with ClipPath for correct alignment.
  Widget _buildParallelogram(
      Widget child, Color color, BoxBorder? border, List<BoxShadow> shadow) {
    return Container(
      width: block.size.width,
      height: block.size.height,
      child: ClipPath(
        clipper: _ParallelogramClipper(skew: 0.3),
        child: Container(
          decoration: _baseDecoration(color, border).copyWith(
            borderRadius: BorderRadius.circular(4),
            boxShadow: shadow,
          ),
          child: child, // The text is now correctly centered
        ),
      ),
    );
  }
// ^^^ --- END OF REPLACEMENT --- ^^^
}

// vvv --- ADD THIS NEW CLIPPER CLASS --- vvv
/// Custom clipper that creates a diamond path.
class _DiamondClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) { // <-- Change 'getPath' to 'getClip'
    return Path()
      ..moveTo(size.width / 2, 0) // Top center
      ..lineTo(size.width, size.height / 2) // Right center
      ..lineTo(size.width / 2, size.height) // Bottom center
      ..lineTo(0, size.height / 2) // Left center
      ..close();
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
// ^^^ --- END OF NEW CLASS --- ^^^

// vvv --- ADD THIS NEW CLIPPER CLASS --- vvv
/// Custom clipper that creates a parallelogram path.
class _ParallelogramClipper extends CustomClipper<Path> {
  final double skew; // How much to skew, e.g., 0.3
  _ParallelogramClipper({this.skew = 0.3});

  @override
  Path getClip(Size size) { // <-- Change 'getPath' to 'getClip'
    final skewAmount = size.width * skew;
    return Path()
      ..moveTo(skewAmount, 0) // Top left
      ..lineTo(size.width, 0) // Top right
      ..lineTo(size.width - skewAmount, size.height) // Bottom right
      ..lineTo(0, size.height) // Bottom left
      ..close();
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
// ^^^ --- END OF NEW CLASS --- ^^^