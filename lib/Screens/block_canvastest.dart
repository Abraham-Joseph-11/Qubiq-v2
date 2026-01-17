import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../../Models/BlockModels.dart';
import '../../Providers/block_provider.dart';

class BlockCanvas extends StatefulWidget {
  const BlockCanvas({super.key});

  @override
  State<BlockCanvas> createState() => _BlockCanvasState();
}

class _BlockCanvasState extends State<BlockCanvas> {
  final GlobalKey _canvasKey = GlobalKey();
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    // ✅ Initial view: Centers the camera on the 5000x5000 workspace
    _transformationController.value = Matrix4.identity()..translate(-2100.0, -2200.0);
  }

  void _updateZoom(double scaleFactor) {
    // Get current matrix and scale
    final Matrix4 currentMatrix = _transformationController.value;
    final double currentScale = currentMatrix.getMaxScaleOnAxis();

    // Calculate target scale and clamp it
    final double targetScale = (currentScale * scaleFactor).clamp(0.5, 3.0);

    // Calculate the actual multiplier needed to reach the target scale
    final double actualMultiplier = targetScale / currentScale;

    setState(() {
      // ✅ FIX: Multiply the existing matrix by the scale.
      // This preserves your current pan position so blocks don't disappear.
      _transformationController.value = currentMatrix..scale(actualMultiplier);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        key: _canvasKey,
        color: const Color(0xFFF5F5F5),
        child: Stack(
          children: [
            // 1. THE ZOOMABLE CANVAS AREA
            Consumer<BlockProvider>(
              builder: (context, provider, _) => DragTarget<BlockModels>(
                onWillAccept: (item) => item is BlockModels,
                onAcceptWithDetails: (details) {
                  final box = _canvasKey.currentContext!.findRenderObject() as RenderBox;
                  final local = box.globalToLocal(details.offset);

                  // ✅ Map screen touch coordinates to the zoomed canvas scene
                  final sceneOffset = _transformationController.toScene(local);

                  final data = details.data;
                  provider.addBlock(BlockModels(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    position: sceneOffset,
                    label: data.label,
                    bleData: data.bleData,
                    block: data.block,
                    type: data.type,
                    size: Size(data.size.width, data.size.height),
                    child: provider.parentId,
                    leftSnapId: data.leftSnapId,
                    rightSnapId: data.rightSnapId,
                    animationType: data.animationType,
                    animationSide: data.animationSide,
                    innerLoopLeftSnapId: data.innerLoopLeftSnapId,
                    innerLoopRightSnapId: data.innerLoopRightSnapId,
                    children: data.children,
                    value: data.value,
                  ));
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    provider.trySnapAnimation(data.id);
                  });
                },
                builder: (_, __, ___) => InteractiveViewer(
                  transformationController: _transformationController,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  minScale: 0.5,
                  maxScale: 3.0,
                  constrained: false, // ✅ Required for a workspace larger than the screen
                  child: SizedBox(
                    width: 5000,
                    height: 5000,
                    child: Stack(
                      children: [
                        // Background Grid
                        CustomPaint(
                            size: const Size(5000, 5000),
                            painter: _GridPainter()
                        ),
                        // Render blocks safely
                        for (var block in provider.blocks)
                          _CanvasBlock(
                            key: ValueKey(block.id),
                            id: block.id,
                            controller: _transformationController,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 2. TOP ZOOM CONTROLS
            Positioned(
              bottom: 100,
              right: 16,
              child: Column(
                children: [
                  // Reset View Button
                  _zoomBtn(Icons.center_focus_strong, "reset_view", () {
                    setState(() {
                      _transformationController.value = Matrix4.identity()
                        ..translate(-2100.0, -2200.0);
                    });
                  }),
                ],
              ),
            ),

            // 3. BOTTOM RESET BUTTON
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                mini: true,
                heroTag: 'reset_canvas_btn',
                backgroundColor: Colors.redAccent,
                onPressed: () {
                  context.read<BlockProvider>().resetAll();
                },
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _zoomBtn(IconData icon, String tag, VoidCallback onPressed) {
    return FloatingActionButton(
      mini: true,
      heroTag: tag,
      backgroundColor: Colors.white,
      onPressed: onPressed,
      child: Icon(icon, color: Colors.blueAccent),
    );
  }
}

class _CanvasBlock extends StatefulWidget {
  final String id;
  final TransformationController controller;
  const _CanvasBlock({Key? key, required this.id, required this.controller}) : super(key: key);

  @override
  State<_CanvasBlock> createState() => _CanvasBlockState();
}

class _CanvasBlockState extends State<_CanvasBlock> {
  @override
  Widget build(BuildContext context) {
    final provider = context.read<BlockProvider>();

    // SAFETY: Use index check to prevent crashes during canvas reset
    final blocks = context.select<BlockProvider, List<BlockModels>>((p) => p.blocks);
    final blockIndex = blocks.indexWhere((b) => b.id == widget.id);

    if (blockIndex == -1) return const SizedBox.shrink();

    final block = blocks[blockIndex];

    return Positioned(
      left: block.position.dx,
      top: block.position.dy - block.size.height,
      child: GestureDetector(
        onPanStart: (d) {
          provider.bringToFront(widget.id);
          provider.bringChainToFront(block.rightSnapId);
          provider.detachBlockFromLoopWidth(widget.id);
          provider.removeLeftSnapId(widget.id);
        },
        onPanUpdate: (d) {
          // ✅ Normalize movement by zoom scale so blocks move naturally
          final double scale = widget.controller.value.getMaxScaleOnAxis();
          provider.updatePositionById(widget.id, block.position + (d.delta / scale));
        },
        onPanEnd: (d) => provider.trySnapAnimation(widget.id),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (block.type == 'loop')
              Container(
                width: block.size.width,
                height: block.size.height,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(block.block),
                    fit: BoxFit.fill,
                    centerSlice: const Rect.fromLTWH(70, 21, 7, 7),
                  ),
                ),
              ),
            if (block.type == 'movement')
              SvgPicture.asset(block.block, width: block.size.width, height: block.size.height),

            Positioned(
              left: block.type == 'movement' ? 6 : null,
              right: block.type == 'loop' ? 5 : null,
              top: 5,
              child: SvgPicture.asset(block.label, width: 50, height: 50),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.grey.shade300;
    const step = 40.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}