import 'package:flutter/material.dart';

class BlockModels {
  String id;
  Offset position;
  final String type;
  final String label;
  final String block;
  final String bleData;
  int value;
  String child;
  String leftSnapId;
  String rightSnapId;
  String innerLoopLeftSnapId;
  String innerLoopRightSnapId;
  String animationType;
  String animationSide;
  Size size;
  List<String> children = [];
  double? bottomAnchor;

  BlockModels({
    required this.id,
    required this.position,
    required this.type,
    required this.label,
    required this.block,
    required this.bleData,
    required this.value,
    required this.leftSnapId,
    required this.rightSnapId,
    required this.innerLoopLeftSnapId,
    required this.innerLoopRightSnapId,
    required this.animationType,
    required this.animationSide,
    required this.size,
    required this.child,
    required this.children,
    this.bottomAnchor,
  });

  // --- ADDED THIS FACTORY ---
  factory BlockModels.empty() {
    return BlockModels(
      id: '',
      position: Offset.zero,
      type: '',
      label: '',
      block: '',
      bleData: '',
      value: 0,
      leftSnapId: '',
      rightSnapId: '',
      innerLoopLeftSnapId: '',
      innerLoopRightSnapId: '',
      animationType: '',
      animationSide: '',
      size: Size.zero,
      child: '',
      children: [],
      bottomAnchor: null,
    );
  }

  Offset rightConnector() => Offset(
    position.dx + size.width,
    position.dy,
  );

  Offset leftConnector() => Offset(
    position.dx,
    position.dy,
  );
  Offset rightConnectorAnimation() => Offset(
    position.dx + size.width,
    position.dy - size.width / 2,
  );

  Offset leftConnectorAnimation() => Offset(
    position.dx,
    position.dy - size.width / 2,
  );
  Offset rightConnectorLoop() => Offset(
    position.dx + size.width - 12,
    position.dy - 50,
  );
  Offset leftConnectorLoop() => Offset(
    position.dx + 2,
    position.dy - 50,
  );

  Offset ConnectorInLoop() => Offset(
    position.dx + 40,
    position.dy - 40,
  );
  int loopLength() => children.length;
}