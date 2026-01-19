import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../Models/BlockModels.dart';
import '../../../Providers/block_provider.dart';

class Loop extends StatefulWidget {
  const Loop({super.key});

  @override
  State<Loop> createState() => _LoopState();
}

class _LoopState extends State<Loop> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const SizedBox(width: 16),
          _buildDraggableTemplate('./lib/Resources/loopIcons/Repeat.svg', 'L'),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildDraggableTemplate(String label, String bleData) {
    final provider = context.read<BlockProvider>();
    final template = BlockModels(
      id: '',
      bleData: bleData,
      position: Offset.zero,
      label: label,
      block: 'lib/Resources/loopIcons/repeatblock.png',
      type: 'loop',
      size: Size(158, 75),
      child: '',
      leftSnapId: '',
      rightSnapId: '',
      animationType: '',
      animationSide: '',
      innerLoopLeftSnapId: '',
      innerLoopRightSnapId: '',
      children: [],
      value: 1,
    );
    return Draggable<BlockModels>(
      data: template,
      dragAnchorStrategy: pointerDragAnchorStrategy, // pointer is anchor

      feedback: Material(
        color: Colors.transparent, // prevents overlay Material styling
        child: Transform.translate(
          offset: Offset(
              0,
              -template.size
                  .height), // shift the feedback up so pointer is at bottom-left
          child: _blockWidget(template, opacity: 1),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: _blockWidget(template)),
      child: _blockWidget(template),
      onDragStarted: () {
        final uuid = Uuid();
        final id = uuid.v4();
        template.id = id;
      },
      onDragUpdate: (details) {
        final position =
            Offset(details.localPosition.dx, details.localPosition.dy - 62);

        provider.paletteBlockUpdate(template, position);
      },
      onDragEnd: (details) {
        setState(() {});
      },
    );
  }

  Widget _blockWidget(BlockModels b, {double opacity = 1}) {
    return Opacity(
        opacity: opacity,
        child: Stack(
          alignment: Alignment.centerRight,
          children: [
            Container(
              width: b.size.width,
              height: b.size.height,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(b.block),
                  fit: BoxFit.fill,
                  centerSlice: Rect.fromLTWH(75, 21, 10, 10),
                ),
              ),
            ),
            Positioned(
              right: 10,
              child: SvgPicture.asset(
                b.label,
                width: 45,
                height: 45,
              ),
            ),
          ],
        ));
  }
}
