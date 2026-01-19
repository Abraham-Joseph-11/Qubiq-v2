import 'package:flutter/material.dart';
import 'package:little_emmi/Models/flow_block_model.dart';
import 'package:uuid/uuid.dart';

// --- ANIMATION HELPERS ---

/// Holds the info for the currently active animation
class BlockAnimation {
  final String blockId;
  final String animationType; // "math", "assign", "input", "output", "none"

  BlockAnimation({required this.blockId, required this.animationType});
}

/// Helper class for building the combined animation steps
class _AnimationStep {
  final String blockId;
  final String command; // Command type used for animation

  _AnimationStep({required this.blockId, required this.command});
}
// -------------------------


class FlowchartProvider extends ChangeNotifier {
  final List<FlowBlock> _blocks = [];
  final Uuid _uuid = Uuid();

  List<FlowBlock> get blocks => _blocks;

  // State Management
  String? _selectedBlockId;
  String? get selectedBlockId => _selectedBlockId;
  BlockAnimation? _currentAnimation;
  BlockAnimation? get currentAnimation => _currentAnimation;

  // --- Block CRUD and Position ---

  void addBlock(FlowchartBlockType type, Offset position) {
    String content = '';
    Size size = const Size(180, 80);

    switch (type) {
      case FlowchartBlockType.start:
        content = 'Start';
        size = const Size(120, 60);
        break;
      case FlowchartBlockType.end:
        content = 'End';
        size = const Size(120, 60);
        break;
      case FlowchartBlockType.input:
        content = 'score'; // Variable name
        break;
      case FlowchartBlockType.process:
        content = 'variable = 10';
        break;
      case FlowchartBlockType.decision:
        content = 'variable > 10';
        size = const Size(180, 100);
        break;
      case FlowchartBlockType.output:
        content = 'variable'; // Expression to print
        break;
    }

    final newBlock = FlowBlock(
      id: _uuid.v4(),
      position: position,
      type: type,
      content: content,
      size: size,
    );
    _blocks.add(newBlock);
    notifyListeners();
  }

  void updateBlockPosition(String id, Offset delta) {
    try {
      final block = _blocks.firstWhere((b) => b.id == id);
      block.position = block.position + delta;
      notifyListeners();
    } catch (e) {
      debugPrint("Could not find block to update position: $id");
    }
  }

  void updateBlockContent(String id, String newContent) {
    try {
      final block = _blocks.firstWhere((b) => b.id == id);

      // Sanitization: Ensure Input blocks only hold simple variable names
      if (block.type == FlowchartBlockType.input) {
        if (!newContent.startsWith(RegExp(r'[a-zA-Z_]'))) {
          debugPrint("Input content must start with a letter or underscore.");
          return;
        }
      }

      block.content = newContent.trim();
      notifyListeners();
    } catch (e) {
      debugPrint("Could not find block to update content: $id");
    }
  }

  /// Updates the runtime value of an Input block after user enters data.
  void updateBlockInputValue(String id, String value) {
    try {
      final block = _blocks.firstWhere((b) => b.id == id);
      block.inputValue = value;
    } catch (e) {
      debugPrint("Could not find block to update input value: $id");
    }
  }

  void deleteBlock(String id) {
    _blocks.removeWhere((b) => b.id == id);
    for (var b in _blocks) {
      // Remove any references to the deleted block
      if (b.nextBlockId == id) b.nextBlockId = null;
      if (b.falseBlockId == id) b.falseBlockId = null;
    }
    if (_selectedBlockId == id) _selectedBlockId = null;
    notifyListeners();
  }

  void clearCanvas() {
    _blocks.clear();
    _selectedBlockId = null;
    _currentAnimation = null;
    notifyListeners();
  }

  // --- Linking Logic ---

  void selectBlockForLinking(String blockId) {
    if (_selectedBlockId == null) {
      // This is the first block tapped
      _selectedBlockId = blockId;
    } else {
      // This is the second block tapped, create the link
      linkBlocks(_selectedBlockId!, blockId);
      _selectedBlockId = null; // Clear selection
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedBlockId = null;
    notifyListeners();
  }

  void linkBlocks(String fromId, String toId) {
    if (fromId == toId) return;

    try {
      final fromBlock = _blocks.firstWhere((b) => b.id == fromId);
      final toBlock = _blocks.firstWhere((b) => b.id == toId);

      if (fromBlock.type == FlowchartBlockType.decision) {
        // For decisions, if nextBlockId is empty, link 'True' (nextBlockId)
        if (fromBlock.nextBlockId == null) {
          fromBlock.nextBlockId = toBlock.id;
        }
        // If 'True' is full, link 'False' (falseBlockId)
        else if (fromBlock.falseBlockId == null) {
          fromBlock.falseBlockId = toBlock.id;
        }
        // If both are full, ask the user/overwrite 'True'
        else {
          fromBlock.nextBlockId = toBlock.id;
        }
      } else {
        // All other blocks just use the 'nextBlockId'
        fromBlock.nextBlockId = toBlock.id;
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Error linking blocks: $e");
    }
  }

  // --- Animation & Code Generation Logic ---

  /// Determines the animation type for a given block based on its content.
  String _getAnimationType(FlowBlock block) {
    final content = block.content.toLowerCase();
    switch (block.type) {
      case FlowchartBlockType.input:
        return 'input';
      case FlowchartBlockType.output:
        return 'output';
      case FlowchartBlockType.process:
        if (content.contains('+') || content.contains('-') ||
            content.contains('*') || content.contains('/')) {
          return 'math'; // Math operation
        }
        if (content.contains('=') && !content.contains('==')) {
          return 'assign'; // Assignment
        }
        return 'none';
      default:
        return 'none';
    }
  }

  /// Gets the list of blocks in the order they will be executed (for animation).
  List<FlowBlock> getExecutionSequence() {
    final List<FlowBlock> sequence = [];
    final blocksMap = {for (var b in _blocks) b.id: b};
    FlowBlock? startBlock;
    try {
      startBlock = _blocks.firstWhere((b) => b.type == FlowchartBlockType.start);
    } catch (e) {
      return [];
    }
    _buildSequenceRecursive(blocksMap[startBlock.nextBlockId], blocksMap, sequence);
    return sequence;
  }

  /// Recursive helper to walk the graph and build the execution list for animation.
  void _buildSequenceRecursive(
      FlowBlock? block,
      Map<String, FlowBlock> blocksMap,
      List<FlowBlock> sequence,
      ) {
    if (block == null) return;

    // Add the current block to the animation sequence
    sequence.add(block);

    if (block.type == FlowchartBlockType.decision) {
      // For animation demo, just follow the True path (nextBlockId) once
      _buildSequenceRecursive(blocksMap[block.nextBlockId], blocksMap, sequence);
    } else {
      // Follow the next block
      _buildSequenceRecursive(blocksMap[block.nextBlockId], blocksMap, sequence);
    }
  }

  /// Runs the visual-only animation by stepping through the blocks.
  Future<void> runVisualAnimation() async {
    final sequence = getExecutionSequence();

    for (final block in sequence) {
      final animType = _getAnimationType(block);

      // Update the UI to show the animation for this block
      _currentAnimation = BlockAnimation(blockId: block.id, animationType: animType);
      notifyListeners();

      // Wait for a short time so the user can see the animation
      await Future.delayed(const Duration(milliseconds: 750));
    }

    // Clear the animation
    _currentAnimation = null;
    notifyListeners();
  }


  String generatePythonCode() {
    String code = "";
    final blocksMap = {for (var b in _blocks) b.id: b};
    FlowBlock? startBlock;
    try {
      startBlock = _blocks.firstWhere((b) => b.type == FlowchartBlockType.start);
    } catch (e) {
      return "# ERROR: Flowchart must start with a 'Start' block.";
    }

    // --- 1. INPUT ASSIGNMENTS (Top of script) ---
    for (final block in _blocks) {
      if (block.type == FlowchartBlockType.input && block.inputValue != null) {
        code += '${block.content} = ${block.inputValue}\n';
      }
    }
    if (code.isNotEmpty) {
      code += "\n";
    }

    final codeBuffer = StringBuffer(code);

    // 2. Start the recursive generation (from the block AFTER 'Start')
    if(startBlock.nextBlockId != null) {
      _buildCodeRecursive(
        startBlock.nextBlockId,
        blocksMap,
        codeBuffer,
        0,
      );
    }

    return codeBuffer.toString();
  }

  /// Private helper to walk the graph and build the Python code string.
  void _buildCodeRecursive(
      String? currentBlockId,
      Map<String, FlowBlock> blocksMap,
      StringBuffer code,
      int indentLevel,
      ) {
    FlowBlock? block = blocksMap[currentBlockId];
    if (block == null) return; // Stop if no block found

    final indent = '    ' * indentLevel; // 4 spaces per level
    String? nextBlockId = block.nextBlockId;

    switch (block.type) {
      case FlowchartBlockType.start:
      case FlowchartBlockType.end:
      // Start and End blocks don't generate code.
        break;

      case FlowchartBlockType.input:
      // Input assignments are handled at the top of the script.
        break;

      case FlowchartBlockType.process:
        code.writeln('$indent${block.content}');
        break;

      case FlowchartBlockType.output:
      // Output blocks generate the print statement
      // Note: The content of an output block should be the expression to print (e.g., "score").
      // We assume the user has entered the content without 'print()'
        code.writeln('${indent}print(${block.content})');
        break;

      case FlowchartBlockType.decision:
      // Decision blocks generate an if/else structure
        code.writeln('${indent}if ${block.content}:');

        // --- TRUE PATH ---
        _buildCodeRecursive(block.nextBlockId, blocksMap, code, indentLevel + 1);

        // --- FALSE PATH ---
        if (block.falseBlockId != null) {
          code.writeln('${indent}else:');
          _buildCodeRecursive(block.falseBlockId, blocksMap, code, indentLevel + 1);
        }

        // After the if/else block, we return to stop the linear chain.
        // The recursion handled the branching.
        return;
    }

    // Recursively call for the next block (standard flow)
    if (nextBlockId != null) {
      _buildCodeRecursive(nextBlockId, blocksMap, code, indentLevel);
    }
  }
}