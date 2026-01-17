import 'package:flutter/material.dart';
import '../Models/BlockModels.dart';
import '../Services/bluetooth_manager.dart'; // ✅ Required for runCode

class BlockProvider extends ChangeNotifier {
  // ===========================================================================
  // 1. STATE VARIABLES & GETTERS
  // ===========================================================================
  final List<BlockModels> _blocks = [];

  // Bluetooth Buffer
  String bleDataString = '';
  final StringBuffer _bleBuffer = StringBuffer();

  // Animation / Highlighting
  String? _highlightedBlockId;
  String? get highlightedBlockId => _highlightedBlockId;

  // Drag & Drop State
  double snapThreshold = 45;
  bool animationFlag = false;
  String chainRightID = '';
  String? attachLeftID;
  double? chainWidth = 0;
  double? chainHeight;
  String? animationSnapId;
  String parentId = '';

  String loopIdForWidthAnimation = '';
  double loopOverWidth = 158;
  double loopOverHeight = 75;
  List noChangeHeightLoops = [];

  // Robot State
  Offset _robotPosition = Offset.zero;
  Offset get robotPosition => _robotPosition;
  bool isRunning = false;

  // Cache for O(1) lookups
  List<BlockModels> get blocks => _blocks;
  Map<String, BlockModels> get _byId => {for (var b in _blocks) b.id: b};

  // ===========================================================================
  // 2. BLUETOOTH & ROBOT EXECUTION LOGIC
  // ===========================================================================

  /// Main function to Run Code via Bluetooth AND Animate Locally
  Future<void> runCode(BluetoothManager bluetooth) async {
    if (_blocks.isEmpty || isRunning) {
      print("⚠️ Cannot run: No blocks or already running.");
      return;
    }

    try {
      // Find Start Block (No left connection, not inside a loop)
      final startBlock = _blocks.firstWhere(
            (b) => b.leftSnapId.isEmpty && b.child.isEmpty,
        orElse: () => _blocks.isNotEmpty ? _blocks.first : BlockModels.empty(),
      );

      if (startBlock.id.isEmpty) return;

      isRunning = true;
      notifyListeners();

      // 1. Animate the Block Highlighting (Visual Feedback)
      await animateChainHighlight(startBlock.id);

      // 2. Generate Command (e.g., "FFF")
      String flatCommand = _generateFlatSequence(startBlock.id);
      print("🤖 Sending to Robot: $flatCommand");

      // 3. Send to Bluetooth
      if (flatCommand.isNotEmpty) {
        bluetooth.sendData(flatCommand);
      }

      // 4. Animate the Robot Character on Screen
      await _executeCommandString(flatCommand);

      isRunning = false;
      notifyListeners();
    } catch (e) {
      print("❌ Error running code: $e");
      isRunning = false;
      notifyListeners();
    }
  }

  /// Helper: Turns the block tree into a flat string (e.g. Loop 2(F) -> FF)
  String _generateFlatSequence(String startId) {
    StringBuffer buffer = StringBuffer();
    String? currentId = startId;
    final byId = _byId;

    while (currentId != null && currentId.isNotEmpty) {
      final block = byId[currentId];
      if (block == null) break;

      if (block.type == 'loop') {
        String innerSeq = "";
        if (block.innerLoopLeftSnapId.isNotEmpty) {
          innerSeq = _generateFlatSequence(block.innerLoopLeftSnapId);
        }
        for (int i = 0; i < block.value; i++) {
          buffer.write(innerSeq);
        }
      } else if (block.type == 'movement') {
        buffer.write(block.bleData);
      }
      currentId = block.rightSnapId;
    }
    return buffer.toString();
  }

  /// Public method to get command string (for testing/compatibility)
  String generateCommandString(String startId) {
    return _generateFlatSequence(startId);
  }

  /// Run animation locally (for testing without bluetooth)
  Future<void> runAnimation(String commandString) async {
    await _executeCommandString(commandString);
  }

  /// Internal: Moves the robot character on the screen
  Future<void> _executeCommandString(String commandString) async {
    const double step = 25.0;
    for (int i = 0; i < commandString.length; i++) {
      final char = commandString[i];
      switch (char.toUpperCase()) {
        case 'F': _robotPosition = Offset(_robotPosition.dx + step, _robotPosition.dy); break;
        case 'B': _robotPosition = Offset(_robotPosition.dx - step, _robotPosition.dy); break;
        case 'U': _robotPosition = Offset(_robotPosition.dx, _robotPosition.dy - step); break;
        case 'D': _robotPosition = Offset(_robotPosition.dx, _robotPosition.dy + step); break;
      }
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  /// Highlights blocks one by one to show execution flow
  Future<void> animateChainHighlight(String startId) async {
    final byId = _byId;
    String? currentId = startId;

    // Traverse logic (simplified for highlighting)
    while (currentId != null && currentId.isNotEmpty) {
      final block = byId[currentId];
      if (block == null) break;

      _highlightedBlockId = block.id;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 200));

      if (block.type == 'loop' && block.innerLoopLeftSnapId.isNotEmpty) {
        // Highlight inside loop
        for(int k=0; k<block.value; k++) {
          await animateChainHighlight(block.innerLoopLeftSnapId);
        }
      }

      currentId = block.rightSnapId;
    }
    _highlightedBlockId = null;
    notifyListeners();
  }

  // ===========================================================================
  // 3. RESET & UTILS
  // ===========================================================================

  void resetRobotPosition() {
    _robotPosition = Offset.zero;
    notifyListeners();
  }

  void resetAll() {
    _blocks.clear();
    resetRobotPosition();
    bleDataString = '';
    chainRightID = '';
    chainWidth = 0;
    parentId = '';
    loopIdForWidthAnimation = '';
    loopOverWidth = 158;
    loopOverHeight = 75;
    notifyListeners();
  }

  void updateBlockValue(String id, int newValue) {
    try {
      final block = _blocks.firstWhere((b) => b.id == id);
      block.value = newValue;
      notifyListeners();
    } catch (e) {
      debugPrint("Error updating block value: $e");
    }
  }

  // ===========================================================================
  // 4. DRAG AND DROP LOGIC (CORE ENGINE)
  // ===========================================================================

  double _shiftAmountForMoving(BlockModels moving) {
    if (moving.type == 'movement') return moving.size.width - 1;
    if (moving.type == 'loop') return moving.size.width - 10;
    return 0;
  }

  void addBlock(BlockModels item) {
    _blocks.add(item);
    bleDataString = bleDataString + item.bleData;
    notifyListeners();
  }

  // inside your build method


  void bringToFront(String id) {
    final idx = _blocks.indexWhere((blk) => blk.id == id);
    if (idx == -1) return;

    final block = _blocks.removeAt(idx);
    _blocks.add(block);

    if (block.type == 'loop' && block.children.isNotEmpty) {
      final List<String> childIds = List<String>.from(block.children);
      for (final childId in childIds) {
        final idxChild = _blocks.indexWhere((blk) => blk.id == childId);
        if (idxChild == -1) continue;
        final child = _blocks.removeAt(idxChild);
        _blocks.add(child);
      }
    }
    if (block.rightSnapId != '') {
      bringChainToFront(block.rightSnapId);
    }
    animationSnapId = '';
    notifyListeners();
  }

  void bringChainToFront(String id) {
    var current = id;
    while (current.isNotEmpty) {
      final idx = _blocks.indexWhere((blk) => blk.id == current);
      if (idx == -1) return;
      final block = _blocks.removeAt(idx);
      _blocks.add(block);
      if (block.type == 'loop') {
        for (var childID in block.children) {
          bringChainToFront(childID);
        }
      }
      current = block.rightSnapId;
    }
  }

  // --- CHAIN SHIFTING HELPERS ---

  void _shiftChain(String startId, double dx) {
    var byId = _byId;
    var current = startId;
    while (current.isNotEmpty) {
      final block = byId[current];
      if (block == null) break;
      block.position = Offset(block.position.dx + dx, block.position.dy);
      if (block.type == 'loop') {
        for (var childID in block.children) {
          _shiftChainInsideLoop(childID, dx);
        }
      }
      current = block.rightSnapId;
    }
  }

  void _shiftChainInsideLoop(String startId, double dx) {
    var byId = _byId;
    var current = startId;
    final block = byId[current];
    if (block == null) return;
    block.position = Offset(block.position.dx + dx, block.position.dy);
    if (block.type == 'loop') {
      for (var childID in block.children) {
        _shiftChainInsideLoop(childID, dx);
      }
    }
  }

  void _shiftChainSnap(String startId, double dx, double dy) {
    var byId = _byId;
    var current = startId;
    while (current.isNotEmpty) {
      final block = byId[current];
      if (block == null) break;
      block.position = Offset(block.position.dx + dx, block.position.dy + dy);
      if (block.type == 'loop') {
        for (var childID in block.children) {
          _shiftChainSnapInsideLoop(childID, dx, dy);
        }
      }
      current = block.rightSnapId;
    }
  }

  void _shiftChainSnapInsideLoop(String startId, double dx, double dy) {
    var byId = _byId;
    var current = startId;
    final block = byId[current];
    if (block == null) return;
    block.position = Offset(block.position.dx + dx, block.position.dy + dy);
    if (block.type == 'loop') {
      for (var childID in block.children) {
        _shiftChainInsideLoop(childID, dx);
      }
    }
  }

  // --- LOOP ATTACHMENT LOGIC ---

  void _snapChainLoop(String startId, BlockModels loop) {
    var byId = _byId;
    var current = startId;
    while (current.isNotEmpty) {
      final block = byId[current];
      if (block == null) break;
      block.child = loop.id;
      if (!loop.children.contains(block.id)) {
        loop.children.add(block.id);
      }
      current = block.rightSnapId;
    }
  }

  void _attachToLoopIfAny(BlockModels other, BlockModels moving) {
    if (other.child == '') return;
    final loop = _byId[other.child];
    if (loop == null) return;
    if (!loop.children.contains(moving.id)) {
      loop.children.add(moving.id);
    }
    final length = loop.children.length;
    final desiredWidth = 158 + (60 * (length - 1));
    loop.size = Size(desiredWidth.toDouble(), loop.size.height);
    moving.child = loop.id;
    parentId = loop.id;
  }

  void _detachFromLoopIfAny(BlockModels other, BlockModels moving) {
    if (other.child == '') return;
    final loop = _byId[other.child];
    if (loop == null) return;
    loop.children.remove(moving.id);
    final length = loop.children.length;
    final desiredWidth = 158 + (60 * (length - 1));
    loop.size = Size(desiredWidth.toDouble(), loop.size.height);
    moving.child = '';
    parentId = '';
  }

  void detachBlockFromLoopWidth(String id) {
    final index = blocks.indexWhere((b) => b.id == id);
    if (index == -1) return;
    if (_blocks[index].child == '') return;
    final byId = _byId;
    final loopBlock = byId[_blocks[index].child];
    if (loopBlock == null) {
      _blocks[index].child = '';
      return;
    }
    loopBlock.children.remove(_blocks[index].id);
    String currentId = _blocks[index].rightSnapId;
    double sumWidths = 60;
    if (_blocks[index].leftSnapId == loopBlock.id) {
      sumWidths = 0.0;
    }
    while (currentId.isNotEmpty && currentId != loopBlock.id) {
      final chained = byId[currentId];
      if (chained == null) break;
      sumWidths = sumWidths + (chained.size.width - 1);
      chained.child = '';
      loopBlock.children.remove(currentId);
      currentId = chained.rightSnapId;
    }
    final double newWidth = loopBlock.size.width - sumWidths;
    loopBlock.size = Size(newWidth, loopBlock.size.height);
    _shiftChain(loopBlock.rightSnapId, -sumWidths);
    _blocks[index].child = '';
  }

  void removeLeftSnapId(String id) {
    final idx = blocks.indexWhere((b) => b.id == id);
    if (idx == -1) return;
    final leftTargetId = _blocks[idx].leftSnapId;
    if (leftTargetId.isNotEmpty) {
      final byId = _byId;
      final leftBlock = byId[leftTargetId];
      if (_blocks[idx].id == leftBlock?.innerLoopLeftSnapId) {
        leftBlock?.innerLoopLeftSnapId = '';
      } else if (leftBlock != null) {
        leftBlock.rightSnapId = '';
      }
    }
    _blocks[idx].leftSnapId = '';
    notifyListeners();
  }

  void updatePositionById(String id, Offset newPos) {
    final index = blocks.indexWhere((b) => b.id == id);
    if (index == -1) return;

    if (_blocks[index].leftSnapId.isEmpty) {
      chainWidth = 0;
      final currentBlock = _blocks[index];
      final movingPosition = currentBlock.position;
      final dxChange = movingPosition.dx - newPos.dx;
      final dyChange = movingPosition.dy - newPos.dy;
      final Map<String, BlockModels> byId = _byId;

      void shiftBlock(BlockModels b) {
        b.position = b.position.translate(-dxChange, -dyChange);
      }
      void moveChildrenIfLoop(BlockModels loopBlock) {
        if (loopBlock.type == 'loop' && loopBlock.children.isNotEmpty) {
          for (final childId in List<String>.from(loopBlock.children)) {
            final child = byId[childId];
            if (child != null) shiftBlock(child);
          }
        }
      }
      moveChildrenIfLoop(currentBlock);
      currentBlock.position = newPos;
      var currentRightSnapId = currentBlock.rightSnapId;
      var currentId = currentBlock.id;
      while (currentRightSnapId.isNotEmpty) {
        final next = byId[currentRightSnapId];
        if (next == null) break;
        if (next.leftSnapId != currentId) break;
        moveChildrenIfLoop(next);
        shiftBlock(next);
        if (next.type == 'movement') {
          chainWidth = (chainWidth ?? 0) + next.size.width - 1;
        } else if (next.type == 'loop') {
          chainWidth = (chainWidth ?? 0) + next.size.width - 11;
        }
        currentId = next.id;
        currentRightSnapId = next.rightSnapId;
      }
      chainRightID = currentId;
    }
    shadowAnimation(index, null);
    notifyListeners();
  }

  void paletteBlockUpdate(BlockModels block, Offset newPos) {
    final updatedBlock = BlockModels(
      id: block.id,
      position: newPos,
      type: block.type,
      label: block.label,
      block: block.block,
      bleData: block.bleData,
      leftSnapId: block.leftSnapId,
      rightSnapId: block.rightSnapId,
      innerLoopLeftSnapId: block.innerLoopLeftSnapId,
      innerLoopRightSnapId: block.innerLoopRightSnapId,
      animationType: block.animationType,
      animationSide: block.animationSide,
      size: block.size,
      child: block.child,
      children: block.children,
      value: block.value,
    );
    shadowAnimation(1, updatedBlock);
  }

  // --- ANIMATION / SNAP DETECTION ---

  void shadowAnimation(int idx, BlockModels? block) {
    final moving = block ?? _blocks[idx];
    var mr = moving.rightConnectorAnimation();
    var ml = moving.leftConnectorAnimation();
    if (moving.type == 'loop') {
      mr = moving.rightConnectorLoop();
      ml = moving.leftConnectorLoop();
    }

    for (int j = 0; j < _blocks.length; j++) {
      final other = _blocks[j];
      var ol = other.leftConnectorAnimation();
      var or = other.rightConnectorAnimation();
      if (other.type == 'loop') {
        ol = other.leftConnectorLoop();
        or = other.rightConnectorLoop();
        final loopConn = other.ConnectorInLoop();
        if ((ml - loopConn).distance < 35 && other.animationType.isEmpty && !animationFlag) {
          other.animationType = moving.type;
          animationFlag = true;
          animationSnapId = other.id;
          if (moving.type == 'loop') {
            other.size = Size(other.size.width + 100, other.size.height + 16);
          }
          if (other.innerLoopLeftSnapId != '') {
            final shiftAmount = _shiftAmountForMoving(moving);
            _shiftChain(other.innerLoopLeftSnapId, shiftAmount);
            other.size = Size(other.size.width + shiftAmount, other.size.height);
          }
          if (other.rightSnapId != '' && other.innerLoopLeftSnapId != '') {
            final shiftAmount = _shiftAmountForMoving(moving);
            _shiftChain(other.rightSnapId, shiftAmount);
          }
          other.animationSide = 'leftInner';
          notifyListeners();
          return;
        }
        if ((ml - loopConn).distance > 35 && other.animationType.isNotEmpty && other.animationSide == 'leftInner') {
          other.animationType = '';
          animationFlag = false;
          animationSnapId = '';
          other.animationSide = '';
          if (moving.type == 'loop') {
            other.size = Size(other.size.width - 100, other.size.height - 16);
          }
          if (other.innerLoopLeftSnapId != '') {
            final shiftAmount = _shiftAmountForMoving(moving);
            _shiftChain(other.innerLoopLeftSnapId, -shiftAmount);
            other.size = Size(other.size.width - shiftAmount, other.size.height);
          }
          if (other.rightSnapId != '' && other.innerLoopLeftSnapId != '') {
            final shiftAmount = _shiftAmountForMoving(moving);
            _shiftChain(other.rightSnapId, -shiftAmount);
          }
          notifyListeners();
          return;
        }
      }

      // Left snap
      if ((mr - ol).distance < snapThreshold && other.animationType.isEmpty && !animationFlag && other.leftSnapId == '') {
        other.animationType = moving.type;
        animationFlag = true;
        animationSnapId = other.id;
        other.animationSide = 'left';
        notifyListeners();
        return;
      }
      if ((mr - ol).distance > snapThreshold && other.animationType.isNotEmpty && other.animationSide == 'left') {
        other.animationType = '';
        other.animationSide = '';
        animationFlag = false;
        animationSnapId = '';
        notifyListeners();
        return;
      }

      // Right snap
      if ((ml - or).distance < snapThreshold && other.animationType.isEmpty && !animationFlag) {
        other.animationType = moving.type;
        animationFlag = true;
        _attachToLoopIfAny(other, moving);
        if (other.rightSnapId != '') {
          final shiftAmount = _shiftAmountForMoving(moving);
          _shiftChain(other.rightSnapId, shiftAmount);
        }
        if (other.child != '') {
          final loop = _byId[other.child];
          if (loop?.rightSnapId != '') {
            final shiftAmount = _shiftAmountForMoving(moving);
            _shiftChain(loop!.rightSnapId, shiftAmount);
          }
        }
        other.animationSide = 'right';
        animationSnapId = other.id;
        if (other.type == 'loop') {
          loopIdForWidthAnimation = other.id;
        }
        notifyListeners();
        return;
      }

      if ((ml - or).distance > snapThreshold && other.animationType.isNotEmpty && other.animationSide == 'right') {
        other.animationType = '';
        other.animationSide = '';
        _detachFromLoopIfAny(other, moving);
        if (other.rightSnapId != '') {
          final shiftAmount = _shiftAmountForMoving(moving);
          _shiftChain(other.rightSnapId, -shiftAmount);
        }
        if (other.child != '') {
          final loop = _byId[other.child];
          if (loop?.rightSnapId != '') {
            final shiftAmount = _shiftAmountForMoving(moving);
            _shiftChain(loop!.rightSnapId, -shiftAmount);
          }
        }
        animationFlag = false;
        animationSnapId = '';
        if (other.type == 'loop') {
          loopIdForWidthAnimation = other.id;
        }
        notifyListeners();
        return;
      }
    }
  }

  void trySnapAnimation(String id) {
    if (animationSnapId == null || animationSnapId!.isEmpty) return;
    final animationIdx = _blocks.indexWhere((b) => b.id == animationSnapId);
    final movingIdx = _blocks.indexWhere((b) => b.id == id);
    if (animationIdx == -1 || movingIdx == -1) return;

    final snapBlock = _blocks[animationIdx];
    final movingBlock = _blocks[movingIdx];
    final byId = _byId;

    var sl = snapBlock.leftConnector();
    var sr = snapBlock.rightConnector();
    if (snapBlock.type == 'loop') {
      sl = snapBlock.leftConnectorLoop();
      sr = snapBlock.rightConnectorLoop();
    }

    if (snapBlock.animationSide == 'leftInner') {
      final oldPos = movingBlock.position;
      if (movingBlock.type == 'movement') {
        movingBlock.position = Offset(sl.dx + 29, sl.dy + 49.5);
      } else if (movingBlock.type == 'loop') {
        movingBlock.position = Offset(sl.dx + 33, sl.dy + 50);
      }
      movingBlock.child = snapBlock.id;
      snapBlock.children.add(movingBlock.id);
      movingBlock.leftSnapId = snapBlock.id;
      snapBlock.animationType = '';
      snapBlock.animationSide = '';
      animationFlag = false;
      animationSnapId = '';

      if (snapBlock.rightSnapId.isNotEmpty) {
        _shiftChain(snapBlock.rightSnapId, chainWidth ?? 0);
      }
      final chainRightBlock = movingBlock.rightSnapId.isNotEmpty ? byId[chainRightID] : movingBlock;
      if (movingBlock.rightSnapId.isNotEmpty) {
        snapBlock.size = Size(snapBlock.size.width + (chainWidth ?? 0), snapBlock.size.height);
        final dxChange = movingBlock.position.dx - oldPos.dx;
        final dyChange = movingBlock.position.dy - oldPos.dy;
        _shiftChainSnap(movingBlock.rightSnapId, dxChange, dyChange);
        _snapChainLoop(movingBlock.rightSnapId, snapBlock);
      }
      if (snapBlock.innerLoopLeftSnapId != '') {
        _shiftChain(snapBlock.innerLoopLeftSnapId, chainWidth ?? 0);
        final firstBlockInLoop = byId[snapBlock.innerLoopLeftSnapId];
        firstBlockInLoop?.leftSnapId = chainRightID;
        chainRightBlock?.rightSnapId = snapBlock.innerLoopLeftSnapId;
      }
      snapBlock.innerLoopLeftSnapId = movingBlock.id;
      notifyListeners();
      return;
    }
    else if (snapBlock.animationSide == 'right') {
      final oldPos = movingBlock.position;
      String rightId = '';
      if (snapBlock.rightSnapId.isNotEmpty) {
        _shiftChain(snapBlock.rightSnapId, chainWidth ?? 0);
        rightId = snapBlock.rightSnapId;
      }
      if (snapBlock.child != '') {
        final loop = _byId[snapBlock.child];
        loop?.size = Size(loop.size.width + (chainWidth ?? 0), loop.size.height);
        _snapChainLoop(movingBlock.rightSnapId, loop!);
        if (loop.rightSnapId.isNotEmpty) {
          _shiftChain(loop.rightSnapId, chainWidth ?? 0);
        }
      }
      if (movingBlock.type == 'movement') {
        movingBlock.leftSnapId = snapBlock.id;
        snapBlock.rightSnapId = movingBlock.id;
        if (movingBlock.child != '') {
          parentId = '';
        }
        if (snapBlock.type == 'movement') {
          movingBlock.position = Offset(sr.dx - 1, sr.dy);
        } else if (snapBlock.type == 'loop') {
          movingBlock.position = Offset(sr.dx + 1.8, sr.dy + 50);
        }
        if (movingBlock.rightSnapId.isNotEmpty) {
          final dxChange = movingBlock.position.dx - oldPos.dx;
          final dyChange = movingBlock.position.dy - oldPos.dy;
          _shiftChainSnap(movingBlock.rightSnapId, dxChange, dyChange);
        }
      } else if (movingBlock.type == 'loop') {
        movingBlock.leftSnapId = snapBlock.id;
        snapBlock.rightSnapId = movingBlock.id;
        if (movingBlock.child != '') {
          parentId = '';
        }
        if (snapBlock.type == 'movement') {
          movingBlock.position = Offset(sr.dx - 1, sl.dy);
        } else if (snapBlock.type == 'loop') {
          movingBlock.position = Offset(sr.dx, sr.dy + 50);
        }
        final dxChange = movingBlock.position.dx - oldPos.dx;
        final dyChange = movingBlock.position.dy - oldPos.dy;
        if (movingBlock.children.isNotEmpty) {
          for (final childId in List<String>.from(movingBlock.children)) {
            final child = byId[childId];
            if (child != null) {
              child.position = Offset(child.position.dx + dxChange, child.position.dy + dyChange);
            }
          }
        }
        if (movingBlock.rightSnapId.isNotEmpty) {
          _shiftChainSnap(movingBlock.rightSnapId, dxChange, dyChange);
        }
      }
      if (rightId.isNotEmpty) {
        final rightSnapBlock = _byId[rightId];
        final otherChainFirstBlock = _byId[chainRightID];
        rightSnapBlock!.leftSnapId = chainRightID;
        otherChainFirstBlock?.rightSnapId = rightSnapBlock.id;
      }
      snapBlock.animationType = '';
      snapBlock.animationSide = '';
      animationFlag = false;
      animationSnapId = '';
      chainWidth = 0;
      notifyListeners();
      return;
    }
    else if (snapBlock.animationSide == 'left') {
      if (movingBlock.type == 'movement') {
        movingBlock.rightSnapId = snapBlock.id;
        snapBlock.leftSnapId = movingBlock.id;
        if (snapBlock.type == 'movement') {
          movingBlock.position = Offset(sl.dx - movingBlock.size.width + 1, sl.dy);
        } else if (snapBlock.type == 'loop') {
          movingBlock.position = Offset(sl.dx - movingBlock.size.width - 0.5, sl.dy + 50);
        }
      } else if (movingBlock.type == 'loop') {
        movingBlock.rightSnapId = snapBlock.id;
        snapBlock.leftSnapId = movingBlock.id;
        final oldPos = movingBlock.position;
        if (snapBlock.type == 'movement') {
          movingBlock.position = Offset(sl.dx - movingBlock.size.width + 10, sl.dy);
        } else if (snapBlock.type == 'loop') {
          movingBlock.position = Offset(sl.dx - movingBlock.size.width + 10, sr.dy + 50);
        }
        final dxChange = movingBlock.position.dx - oldPos.dx;
        final dyChange = movingBlock.position.dy - oldPos.dy;
        if (movingBlock.children.isNotEmpty) {
          for (final childId in List<String>.from(movingBlock.children)) {
            final child = byId[childId];
            if (child != null) {
              child.position = Offset(child.position.dx + dxChange, child.position.dy + dyChange);
            }
          }
        }
      }
      snapBlock.animationType = '';
      snapBlock.animationSide = '';
      animationFlag = false;
      animationSnapId = '';
      notifyListeners();
      return;
    }
  }
}