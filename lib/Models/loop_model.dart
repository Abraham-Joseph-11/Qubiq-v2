import 'package:flutter/material.dart';
import 'package:little_emmi/Models/movement_model.dart';

import 'BlockModel.dart';

class LoopModel extends BlockModel {
  Offset position;
  final String label;
  final String block;
  final String bleData;
  final Size size;
  final List<MovementModel> blocks = [];
  LoopModel({
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
