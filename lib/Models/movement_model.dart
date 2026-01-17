import 'package:flutter/material.dart';

import 'BlockModel.dart';

class MovementModel extends BlockModel {
  Offset position;
  final String label;
  final String block;
  final String bleData;
  final Size size;

  MovementModel({
    required this.position,
    required this.label,
    required this.block,
    required this.bleData,
    this.size = const Size(48, 50),
  });

  Offset rightConnector() => Offset(
        position.dx + size.width,
        position.dy + size.height / 2,
      );

  Offset leftConnector() => Offset(
        position.dx,
        position.dy + size.height / 2,
      );
}
