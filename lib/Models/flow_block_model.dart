import 'package:flutter/material.dart';

// Defines the different types of flowchart shapes
enum FlowchartBlockType { start, end, process, decision, input, output }

class FlowBlock {
  final String id;
  Offset position;
  Size size;
  final FlowchartBlockType type;
  String content; // The text/code inside the block, e.g., "x = 10"
  // vvv --- ADD THIS LINE --- vvv
  String? inputValue; // Stores the value the user provides at runtime (e.g., "90")
  // ^^^ --------------------- ^^^

  // Connection IDs
  String? nextBlockId;      // The ID of the block connected below this one
  String? falseBlockId;   // For 'decision' blocks, the "False" path

  FlowBlock({
    required this.id,
    required this.position,
    required this.type,
    this.content = '',
    this.size = const Size(180, 80), // Default size
    this.nextBlockId,
    this.falseBlockId,
    this.inputValue, // <-- ADD TO CONSTRUCTOR
  });
}