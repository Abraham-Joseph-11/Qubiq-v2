import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../Models/BlockModels.dart';
import '../../../Providers/block_provider.dart';

class Movement extends StatefulWidget {
  const Movement({super.key});

  @override
  State<Movement> createState() => _MovementState();
}

class _MovementState extends State<Movement> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      // ✅ CHANGED: Replaced Row with Wrap to fix overflow on mobile
      child: Wrap(
        spacing: 16.0,    // Horizontal gap between blocks
        runSpacing: 12.0, // Vertical gap between lines if wrapped
        alignment: WrapAlignment.start,
        children: [
          _buildDraggableTemplate(
              './lib/Resources/MovementIcons/Foward.svg', 'F'),
          _buildDraggableTemplate(
              './lib/Resources/MovementIcons/Back.svg', 'B'),
          _buildDraggableTemplate('./lib/Resources/MovementIcons/Up.svg', 'U'),
          _buildDraggableTemplate(
              './lib/Resources/MovementIcons/Down.svg', 'D'),
        ],
      ),
    );
  }

  Widget _buildDraggableTemplate(String label, String _bleData) {
    final provider = context.read<BlockProvider>();
    final template = BlockModels(
      id: '',
      bleData: _bleData,
      position: Offset.zero,
      label: label,
      block: './lib/Resources/BlocksStructure/blueCmd.svg',
      type: 'movement',
      size: const Size(61, 60),
      child: '',
      leftSnapId: '',
      rightSnapId: '',
      animationType: '',
      animationSide: '',
      innerLoopLeftSnapId: '',
      innerLoopRightSnapId: '',
      children: ['M'],
      value: 1,
    );
    return Draggable<BlockModels>(
      data: template,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.translate(
          offset: Offset(0, -template.size.height),
          child: _blockWidget(template, opacity: 1),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: _blockWidget(template)),
      child: _blockWidget(template),
      onDragStarted: () {
        final uuid = const Uuid();
        final id = uuid.v4();
        template.id = id;
      },
      onDragUpdate: (details) {
        final position =
        Offset(details.localPosition.dx, details.localPosition.dy - 62);
        provider.paletteBlockUpdate(template, position);
      },
    );
  }

  Widget _blockWidget(BlockModels b, {double opacity = 1}) {
    return Opacity(
        opacity: opacity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SvgPicture.asset(
              b.block,
              width: b.size.width,
              height: b.size.height,
            ),
            SvgPicture.asset(
              b.label,
              width: 50,
              height: 50,
            ),
          ],
        ));
  }
}