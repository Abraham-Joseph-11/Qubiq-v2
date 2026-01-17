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

  // Controller to handle both pinch-to-zoom and button-zoom
  late TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    // ✅ Initial view: Center the 8000x8000 canvas
    _transformationController.value = Matrix4.identity()..translate(-3600.0, -3800.0);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  /// Manual zoom logic for buttons
  void _updateZoom(double factor) {
    final Matrix4 currentMatrix = _transformationController.value;
    final double currentScale = currentMatrix.getMaxScaleOnAxis();
    final double targetScale = (currentScale * factor).clamp(0.1, 3.0);
    final double actualMultiplier = targetScale / currentScale;

    setState(() {
      _transformationController.value = currentMatrix..scale(actualMultiplier);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900], // Dark background to verify canvas edges
      body: Stack(
        children: [
          // 1. THE ZOOMABLE AREA
          Positioned.fill(
            child: Consumer<BlockProvider>(
              builder: (context, provider, _) => DragTarget<BlockModels>(
                onWillAccept: (item) => true,
                onAcceptWithDetails: (details) {
                  final box = _canvasKey.currentContext!.findRenderObject() as RenderBox;
                  final Offset localOffset = box.globalToLocal(details.offset);

                  // ✅ Map screen drop coordinates to the zoomed scene
                  final Offset sceneOffset = _transformationController.toScene(localOffset);

                  provider.addBlock(BlockModels(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    position: sceneOffset,
                    label: details.data.label,
                    bleData: details.data.bleData,
                    block: details.data.block,
                    type: details.data.type,
                    size: details.data.size,
                    child: provider.parentId,
                    leftSnapId: details.data.leftSnapId,
                    rightSnapId: details.data.rightSnapId,
                    innerLoopLeftSnapId: details.data.innerLoopLeftSnapId,
                    innerLoopRightSnapId: details.data.innerLoopRightSnapId,
                    animationType: details.data.animationType,
                    animationSide: details.data.animationSide,
                    children: List.from(details.data.children),
                    value: details.data.value,
                  ));
                },
                builder: (context, _, __) => InteractiveViewer(
                  key: const ValueKey('MainInteractiveCanvas'),
                  transformationController: _transformationController,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  minScale: 0.1,
                  maxScale: 3.0,
                  panEnabled: true,   // ✅ One-finger pan
                  scaleEnabled: true, // ✅ Two-finger pinch
                  constrained: false,
                  child: Container(
                    width: 8000,
                    height: 8000,
                    color: Colors.white,
                    child: Stack(
                      children: [
                        Positioned.fill(child: CustomPaint(painter: _GridPainter())),
                        // ✅ Render all blocks from Provider
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
          ),

          // 2. ZOOM CONTROLS (Top-Right)
          Positioned(
            top: 50,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _zoomFab(Icons.add, "in", () => _updateZoom(1.2)),
                const SizedBox(height: 10),
                _zoomFab(Icons.remove, "out", () => _updateZoom(0.8)),
                const SizedBox(height: 10),
                _zoomFab(Icons.center_focus_strong, "rst", () {
                  setState(() {
                    _transformationController.value = Matrix4.identity()
                      ..translate(-3600.0, -3800.0);
                  });
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _zoomFab(IconData icon, String tag, VoidCallback onTap) {
    return FloatingActionButton(
      heroTag: tag,
      onPressed: onTap,
      backgroundColor: Colors.blueAccent,
      mini: true,
      child: Icon(icon, color: Colors.white),
    );
  }
}

class _CanvasBlock extends StatelessWidget {
  final String id;
  final TransformationController controller;
  const _CanvasBlock({Key? key, required this.id, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.read<BlockProvider>();
    final block = context.select<BlockProvider, BlockModels>(
          (p) => p.blocks.firstWhere((b) => b.id == id),
    );

    return Positioned(
      left: block.position.dx,
      top: block.position.dy,
      child: GestureDetector(
        onPanStart: (_) => provider.bringToFront(id),
        onPanUpdate: (details) {
          // ✅ Normalize movement by zoom scale to prevent sliding
          final double scale = controller.value.getMaxScaleOnAxis();
          provider.updatePositionById(id, block.position + (details.delta / scale));
        },
        onPanEnd: (_) => provider.trySnapAnimation(id),
        child: Stack(
          children: [
            if (block.type == 'loop')
              Container(
                width: block.size.width,
                height: block.size.height,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(block.block),
                    fit: BoxFit.fill,
                    centerSlice: const Rect.fromLTWH(75, 21, 10, 10),
                  ),
                ),
              ),
            if (block.type == 'movement')
              SvgPicture.asset(block.block, width: block.size.width, height: block.size.height),
            Positioned(
              left: 10,
              top: 10,
              child: SvgPicture.asset(block.label, width: 40, height: 40),
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
    final paint = Paint()..color = Colors.black.withOpacity(0.1)..strokeWidth = 1.0;
    for (double i = 0; i < size.width; i += 100) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 100) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}