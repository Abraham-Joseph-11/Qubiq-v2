import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:little_emmi/Models/flow_block_model.dart';
import 'package:little_emmi/Providers/flowchart_provider.dart';
import 'package:little_emmi/Screens/Flowchart/flowchart_shape_widget.dart';
import 'package:provider/provider.dart';

/// The main workspace for dragging and connecting flowchart blocks.
class FlowchartCanvas extends StatefulWidget {
  const FlowchartCanvas({super.key});

  @override
  State<FlowchartCanvas> createState() => _FlowchartCanvasState();
}

class _FlowchartCanvasState extends State<FlowchartCanvas> {
  final GlobalKey _canvasKey = GlobalKey();

  // (All helper methods like _getIconForAnimation, _buildAnimationOverlay are unchanged)
  IconData _getIconForAnimation(String animType) {
    switch (animType) {
      case 'math': return Icons.calculate_outlined;
      case 'assign': return Icons.edit_outlined;
      case 'input': return Icons.keyboard_outlined;
      case 'output': return Icons.print_outlined;
      default: return Icons.play_arrow;
    }
  }

  Widget _buildAnimationOverlay(BuildContext context, FlowchartProvider provider) {
    final animation = provider.currentAnimation;
    if (animation == null) {
      return const SizedBox.shrink();
    }
    FlowBlock? block;
    try {
      block = provider.blocks.firstWhere((b) => b.id == animation.blockId);
    } catch (e) {
      return const SizedBox.shrink();
    }
    return Positioned(
      left: block.position.dx + (block.size.width / 2) - 20,
      top: block.position.dy + (block.size.height / 2) - 20,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.scale(scale: 1 + (value * 0.5), child: child),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIconForAnimation(animation.animationType),
              color: Colors.yellowAccent,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  // vvv --- ADD THIS NEW WIDGET-BUILDING METHOD --- vvv
  /// Builds the delete button that floats over the selected block.
  Widget _buildDeleteButton(FlowchartProvider provider) {
    if (provider.selectedBlockId == null) {
      return const SizedBox.shrink(); // No block selected, show nothing
    }

    FlowBlock? block;
    try {
      block = provider.blocks.firstWhere((b) => b.id == provider.selectedBlockId);
    } catch (e) {
      return const SizedBox.shrink(); // Block not found
    }

    // Position the delete button above the top-right corner of the block
    return Positioned(
      left: block.position.dx + block.size.width - 15,
      top: block.position.dy - 15,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.redAccent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
          onPressed: () {
            provider.deleteBlock(block!.id);
          },
          padding: EdgeInsets.zero,
          tooltip: "Delete Block",
        ),
      ),
    );
  }
  // ^^^ --- END OF NEW METHOD --- ^^^

  @override
  Widget build(BuildContext context) {
    return Consumer<FlowchartProvider>(
      builder: (context, provider, child) {
        return DragTarget<FlowchartBlockType>(
          builder: (context, candidateData, rejectedData) {
            return GestureDetector(
              onTap: () => provider.clearSelection(),
              child: Container(
                key: _canvasKey,
                // The canvas color is now part of the grid painter
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. Draw the new dot grid background
                    CustomPaint(
                      painter: _GridPainter(
                        dotColor: Colors.grey.shade600,
                        backgroundColor: Colors.grey.shade800,
                      ),
                      size: Size.infinite,
                    ),

                    // 2. Draw all the connecting lines
                    CustomPaint(
                      painter: _LinePainter(
                        blocks: provider.blocks,
                      ),
                      size: Size.infinite,
                    ),

                    // 3. Draw all the blocks
                    ...provider.blocks.map((block) {
                      return _DraggableFlowBlock(
                        key: ValueKey(block.id),
                        block: block,
                      );
                    }).toList(),

                    // 4. Draw the animation overlay
                    _buildAnimationOverlay(context, provider),
                    // vvv --- 5. ADD THE DELETE BUTTON --- vvv
                    _buildDeleteButton(provider),
                    // ^^^ --- END OF ADDITION --- ^^^
                  ],
                ),
              ),
            );
          },
          onAcceptWithDetails: (details) {
            final RenderBox renderBox =
            _canvasKey.currentContext!.findRenderObject() as RenderBox;
            final localPosition = renderBox.globalToLocal(details.offset);
            provider.addBlock(details.data, localPosition);
          },
        );
      },
    );
  }
}

// (_DraggableFlowBlock class is unchanged)
class _DraggableFlowBlock extends StatelessWidget {
  final FlowBlock block;
  const _DraggableFlowBlock({super.key, required this.block});

  void _showEditDialog(BuildContext context, FlowchartProvider provider) {
    if (block.type == FlowchartBlockType.start ||
        block.type == FlowchartBlockType.end) {
      return;
    }
    final TextEditingController controller =
    TextEditingController(text: block.content);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit ${block.type.name} Block"),
          content: TextField(
            controller: controller,
            autofocus: true,
            onSubmitted: (_) {
              provider.updateBlockContent(block.id, controller.text);
              Navigator.of(context).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                provider.updateBlockContent(block.id, controller.text);
                Navigator.of(context).pop();
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FlowchartProvider>();
    final isSelected = provider.selectedBlockId == block.id;

    return Positioned(
      left: block.position.dx,
      top: block.position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          if (provider.selectedBlockId == null) {
            provider.updateBlockPosition(block.id, details.delta);
          }
        },
        onDoubleTap: () {
          _showEditDialog(context, provider);
        },
        onTap: () {
          provider.selectBlockForLinking(block.id);
        },
        child: FlowchartShapeWidget(
          block: block,
          isSelected: isSelected,
        ),
      ),
    );
  }
}

// --- NEW PAINTER FOR THE BACKGROUND ---
class _GridPainter extends CustomPainter {
  final double spacing;
  final double dotRadius;
  final Color dotColor;
  final Color backgroundColor;

  _GridPainter({
    this.spacing = 30.0,
    this.dotRadius = 1.0,
    required this.dotColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Paint the background color
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = backgroundColor);

    // Paint the dots
    final paint = Paint()..color = dotColor;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- UPDATED LINE PAINTER ---
class _LinePainter extends CustomPainter {
  final List<FlowBlock> blocks;

  _LinePainter({required this.blocks});

  // Helper to get connection points
  Offset getTop(FlowBlock block) =>
      block.position + Offset(block.size.width / 2, 0);

  Offset getBottom(FlowBlock block) =>
      block.position + Offset(block.size.width / 2, block.size.height);

  Offset getRight(FlowBlock block) =>
      block.position + Offset(block.size.width, block.size.height / 2);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Define Paints

    // Shadow/Glow paint (draws behind the main line)
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    // Main "True" path paint (White/Grey)
    final truePaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Main "False" path paint (Red)
    final falsePaint = Paint()
      ..color = Colors.redAccent.shade100
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Arrow fills
    final arrowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final falseArrowPaint = Paint()
      ..color = Colors.redAccent.shade100
      ..style = PaintingStyle.fill;

    final blocksMap = {for (var b in blocks) b.id: b};

    for (final block in blocks) {

      // --- DRAW TRUE LINK (Bottom -> Top) ---
      if (block.nextBlockId != null && blocksMap.containsKey(block.nextBlockId)) {
        final toBlock = blocksMap[block.nextBlockId]!;
        final start = getBottom(block);
        final end = getTop(toBlock);

        // Calculate a smooth bezier path
        final path = Path();
        path.moveTo(start.dx, start.dy);

        // Control points determine the curve intensity
        // We pull down from start, and pull up from end
        double verticalDist = (end.dy - start.dy).abs();
        double controlOffset = verticalDist * 0.5;
        // Clamp offset to ensure it doesn't look weird on short distances
        if (controlOffset > 80) controlOffset = 80;
        if (controlOffset < 20) controlOffset = 20;

        path.cubicTo(
          start.dx, start.dy + controlOffset, // Control Point 1 (Down)
          end.dx, end.dy - controlOffset,     // Control Point 2 (Up)
          end.dx, end.dy,                     // End Point
        );

        // Draw Shadow then Line
        canvas.drawPath(path, shadowPaint);
        canvas.drawPath(path, truePaint);

        // Draw Arrow
        _drawStyledArrow(canvas, end, arrowPaint);

        // Label for Decision
        if (block.type == FlowchartBlockType.decision) {
          _drawLabel(canvas, 'True', start + const Offset(5, 5), Colors.white70);
        }
      }

      // --- DRAW FALSE LINK (Right -> Top) ---
      if (block.falseBlockId != null && blocksMap.containsKey(block.falseBlockId)) {
        final toBlock = blocksMap[block.falseBlockId]!;
        final start = getRight(block);
        final end = getTop(toBlock);

        final path = Path();
        path.moveTo(start.dx, start.dy);

        double horizontalDist = (end.dx - start.dx).abs();
        double verticalDist = (end.dy - start.dy).abs();

        // For Right->Top connection, we pull Right from start, and Up from end
        path.cubicTo(
            start.dx + (horizontalDist / 2).clamp(30.0, 100.0), start.dy, // Pull Right
            end.dx, end.dy - (verticalDist / 2).clamp(30.0, 100.0),       // Pull Up
            end.dx, end.dy
        );

        canvas.drawPath(path, shadowPaint);
        canvas.drawPath(path, falsePaint);

        _drawStyledArrow(canvas, end, falseArrowPaint);

        _drawLabel(canvas, 'False', start + const Offset(10, -15), Colors.redAccent);
      }
    }
  }

  // Improved Arrow: Looks like a sleeker chevron
  void _drawStyledArrow(Canvas canvas, Offset pos, Paint paint) {
    final path = Path();
    // Tip of the arrow (touching the block)
    path.moveTo(pos.dx, pos.dy);
    // Left Wing
    path.lineTo(pos.dx - 6, pos.dy - 10);
    // Inner Recess (makes it look sharp)
    path.lineTo(pos.dx, pos.dy - 8);
    // Right Wing
    path.lineTo(pos.dx + 6, pos.dy - 10);
    path.close();

    // Draw shadow for arrow
    canvas.drawShadow(path, Colors.black, 3.0, false);
    canvas.drawPath(path, paint);
  }

  void _drawLabel(Canvas canvas, String text, Offset position, Color color) {
    // Add a small background rectangle for readability
    final textStyle = GoogleFonts.robotoMono(
      color: color,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Draw background bubble
    final bgRect = Rect.fromLTWH(
        position.dx - 2,
        position.dy - 2,
        textPainter.width + 4,
        textPainter.height + 4
    );
    final bgPaint = Paint()..color = Colors.grey.shade900.withOpacity(0.8);
    canvas.drawRRect(RRect.fromRectAndRadius(bgRect, const Radius.circular(4)), bgPaint);

    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}