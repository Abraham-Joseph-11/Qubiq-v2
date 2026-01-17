import 'package:flutter/material.dart';
import 'package:little_emmi/Models/flow_block_model.dart';
import 'package:little_emmi/Screens/Flowchart/flowchart_shape_widget.dart';
import 'package:uuid/uuid.dart';

/// The side panel widget containing all the draggable flowchart shapes.
class FlowchartPalette extends StatelessWidget {
  const FlowchartPalette({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[850],
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Flow Blocks',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),

          // --- Draggable Shapes ---

          _buildDraggableShape(
            type: FlowchartBlockType.start,
            text: 'Start',
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),

          _buildDraggableShape(
            type: FlowchartBlockType.process,
            text: 'Process',
            content: 'variable = 10', // Default content
            color: Colors.blue.shade400,
          ),
          const SizedBox(height: 16),

          // VVV --- THE MISSING INPUT BLOCK --- VVV
          _buildDraggableShape(
            type: FlowchartBlockType.input,
            text: 'Input',
            content: 'name = input()', // Default content
            color: Colors.purple.shade400,
          ),
          const SizedBox(height: 16),
          // ^^^ --- END OF INPUT BLOCK --- ^^^

          _buildDraggableShape(
            type: FlowchartBlockType.decision,
            text: 'Decision',
            content: 'x > 5', // Default content
            color: Colors.green.shade400,
          ),
          const SizedBox(height: 16),

          _buildDraggableShape(
            type: FlowchartBlockType.output,
            text: 'Output',
            content: 'print(variable)', // Default content
            color: Colors.orange.shade400,
          ),
          const SizedBox(height: 16),

          _buildDraggableShape(
            type: FlowchartBlockType.end,
            text: 'End',
            color: Colors.red.shade400,
          ),
        ],
      ),
    );
  }

  /// Helper to create a draggable shape for the palette
  Widget _buildDraggableShape({
    required FlowchartBlockType type,
    required String text,
    String content = '', // Allow content to be passed, defaults to empty
    required Color color,
  }) {
    // This is the dummy block model used to render the shape in the palette
    final blockForDisplay = FlowBlock(
      id: 'palette',
      position: Offset.zero,
      type: type,
      content: text,
      size: (type == FlowchartBlockType.decision) ? const Size(120, 80) : const Size(150, 60),
    );

    // This is the actual data model passed when dragging
    final blockData = FlowBlock(
      id: Uuid().v4(),
      position: Offset.zero,
      type: type,
      // Use the provided content for the actual block data
      content: content.isEmpty ? text : content,
      size: (type == FlowchartBlockType.decision) ? const Size(180, 100) : const Size(180, 80),
    );

    return Draggable<FlowchartBlockType>(
      data: type, // We drop the type, not the full block model
      feedback: Material( // This is what the user sees while dragging
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.8,
          child: FlowchartShapeWidget(block: blockForDisplay),
        ),
      ),
      child: FlowchartShapeWidget(block: blockForDisplay), // This is what sits in the palette
    );
  }
}