import 'package:flutter/material.dart';
import '../Models/BlockModels.dart';

class BlockProvider extends ChangeNotifier {
  final List<BlockModels> _blocks = [];
  final StringBuffer _bleBuffer = StringBuffer();

  // Expose ble data via getter to avoid repeated concatenation overhead.
  String get bleDataString => _bleBuffer.toString();
  List<BlockModels> get blocks => _blocks;
  int get selectedIndex => _selectedIndex;
  double snapThreshold = 45;
  bool animationFlag = false;

  String chainRightID = '';
  double? chainWidth = 0;
  double? chainHeight;
  String? animationSnapId;
  String parentId = '';
  int _selectedIndex = 0;

  String loopIdForWidthAnimation = '';
  double loopOverWidth = 158;
  double loopOverHeight = 75;
  void setSelectedIndex(int i) {
    _selectedIndex = i;
    notifyListeners(); // if you want UI to update
  }

  /// Construct a temporary id->BlockModels map for O(1) lookups.
  Map<String, BlockModels> get _byId => {for (var b in _blocks) b.id: b};

  /// Construct id->index map when index lookups are needed
  Map<String, int> _indexMap() {
    final map = <String, int>{};
    for (var i = 0; i < _blocks.length; i++) {
      map[_blocks[i].id] = i;
    }
    return map;
  }

  double _shiftAmountForMoving(BlockModels moving) {
    if (moving.type == 'movement') return moving.size.width - 1;
    if (moving.type == 'loop') return moving.size.width - 10;
    return 0;
  }

  // -------------- Small helper to reduce duplicate allocations --------------
  void _ensureChildrenCopyAndForEach(
      BlockModels loopBlock, void Function(String childId) fn) {
    if (loopBlock.children.isEmpty) return;
    final copy = List<String>.from(loopBlock.children);
    for (final childId in copy) fn(childId);
  }

  // -------------------- Public methods (optimized) --------------------------

  void bringToFront(String id) {
    final idx = _blocks.indexWhere((blk) => blk.id == id);
    if (idx == -1) return;

    final block = _blocks.removeAt(idx);
    _blocks.add(block);

    // Depth-first: after adding the parent, add each child in order
    for (final childId in List<String>.from(block.children)) {
      final childIdx = _blocks.indexWhere((blk) => blk.id == childId);
      if (childIdx == -1) continue;

      final child = _blocks.removeAt(childIdx);
      _blocks.add(child);

      // Recurse so grandchildren follow immediately after
      bringToFront(childId);
    }

    animationSnapId = '';
    notifyListeners();
  }

  void bringChainToFront(String id) {
    if (id.isEmpty) return;
    var current = id;
    while (current.isNotEmpty) {
      final idx = _blocks.indexWhere((blk) => blk.id == current);
      if (idx == -1) return;
      final block = _blocks.removeAt(idx);
      _blocks.add(block);
      if (block.type == 'loop') {
        // reuse bringChainToFront for children
        for (var childID in List<String>.from(block.children)) {
          bringChainToFront(childID);
        }
      }
      current = block.rightSnapId;
    }
  }

  /// Shift the chain starting from [startId] by dx horizontally.
  void _shiftChain(String startId, double dx) {
    if (startId.isEmpty || dx == 0) return;
    final byId = _byId;
    var current = startId;

    while (current.isNotEmpty) {
      final block = byId[current];
      if (block == null) break;

      // Shift this block
      block.position = Offset(block.position.dx + dx, block.position.dy);

      // If it's a loop, shift all its children (recursively) using helper
      if (block.type == 'loop' && block.children.isNotEmpty) {
        _ensureChildrenCopyAndForEach(
            block, (childId) => _shiftChainInsideLoop(childId, dx, byId));
      }
      current = block.rightSnapId;
    }
  }

  void _shiftChainInsideLoop(
      String startId, double dx, Map<String, BlockModels> byId) {
    final block = byId[startId];
    if (block == null) return;
    block.position = Offset(block.position.dx + dx, block.position.dy);
    if (block.type == 'loop' && block.children.isNotEmpty) {
      _ensureChildrenCopyAndForEach(
          block, (childId) => _shiftChainInsideLoop(childId, dx, byId));
    }
    // next chain element is intentionally not followed here (loop children only)
  }

  void _shiftChainSnap(String startId, double dx, double dy) {
    if (startId.isEmpty || (dx == 0 && dy == 0)) return;
    final byId = _byId;
    var current = startId;

    while (current.isNotEmpty) {
      final block = byId[current];
      if (block == null) break;

      // Shift this block
      block.position = Offset(block.position.dx + dx, block.position.dy + dy);

      // If it's a loop, shift all its children (recursively)
      if (block.type == 'loop' && block.children.isNotEmpty) {
        _ensureChildrenCopyAndForEach(block,
            (childId) => _shiftChainSnapInsideLoop(childId, dx, dy, byId));
      }

      current = block.rightSnapId;
    }
  }

  void _shiftChainSnapInsideLoop(
      String startId, double dx, double dy, Map<String, BlockModels> byId) {
    final block = byId[startId];
    if (block == null) return;
    block.position = Offset(block.position.dx + dx, block.position.dy + dy);
    if (block.type == 'loop' && block.children.isNotEmpty) {
      _ensureChildrenCopyAndForEach(
          block, (childId) => _shiftChainSnapInsideLoop(childId, dx, dy, byId));
    }
  }

  void _snapChainLoop(String startId, BlockModels loop) {
    if (startId.isEmpty) return;
    final byId = _byId;
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

  void _shiftChainLoopOver(String startId, double dx) {
    if (startId.isEmpty) return;
    final byId = _byId;
    var current = startId;
    bool flag = false;
    final block = byId[current];
    final leftBlock = byId[block?.leftSnapId];
    if (leftBlock?.type == 'loop') {
      flag = true;
    }
    while (current.isNotEmpty) {
      final block = byId[current];
      if (block == null) break;

      // Shift this block
      block.position = Offset(block.position.dx + dx, block.position.dy);

      // If it's a loop, shift all its children (recursively) using helper
      if (block.type == 'loop' && block.children.isNotEmpty) {
        _ensureChildrenCopyAndForEach(
            block, (childId) => _shiftChainInsideLoop(childId, dx, byId));
      }
      if (block.type == 'movement') {
        loopOverWidth = loopOverWidth + block.size.width - 1;
      } else if (block.type == 'loop') {
        loopOverWidth = loopOverWidth + block.size.width - 10;
      }
      if (block.size.height > loopOverHeight) {
        loopOverHeight = block.size.height;
      }
      if (block.type == 'loop') flag = true;
      current = block.rightSnapId;
    }
    if (flag) loopOverHeight += 15;
  }

  double desiredHeight = 0;
  double desiredWidth = 0;
  List noChangeHeightLoops = [];

  /// Add [moving] as a child of the loop referenced by other.child (if present).
  void _attachToLoopIfAny(BlockModels other, BlockModels moving) {
    if (other.child.isEmpty) return;
    final byId = _byId;
    final loop = byId[other.child];
    if (loop == null) return;

    if (!loop.children.contains(moving.id)) {
      loop.children.add(moving.id);
    }
    desiredWidth = 0;
    desiredHeight = 0;
    if (moving.type == 'movement') {
      desiredWidth = 60;
    } else if (moving.type == 'loop') {
      desiredWidth = 148;
      if (loop.size.height > 75) {
        desiredHeight = 0;
      } else {
        desiredHeight = 15;
      }
    }
    double tempHeight = desiredHeight;
    loop.size =
        Size(loop.size.width + desiredWidth, loop.size.height + desiredHeight);
    if (loop.child.isNotEmpty) {
      final loopParent = _byId[loop.child];
      if (loopParent == null) return;
      if (loop.size.height + 15 <= loopParent.size.height) {
        desiredHeight = 0;
      }
      _attachToLoopResizeNest(loop.child, desiredWidth, desiredHeight);
    }
    desiredHeight = tempHeight;
    moving.child = loop.id;
    parentId = loop.id;
  }

  void _attachToLoopResizeNest(
      String loopId, double desiredWidth, double desiredHeight) {
    final loop = _byId[loopId];
    if (loop == null) return;
    if (desiredHeight == 0) {
      if (!noChangeHeightLoops.contains(loop.id)) {
        noChangeHeightLoops.add(loop.id);
      }
    }
    loop.size =
        Size(loop.size.width + desiredWidth, loop.size.height + desiredHeight);
    if (loop.rightSnapId.isNotEmpty) {
      _shiftChain(loop.rightSnapId, desiredWidth);
    }
    if (loop.child.isNotEmpty) {
      final loopParent = _byId[loop.child];
      if (loopParent == null) return;
      if (loop.size.height + 15 <= loopParent.size.height) {
        desiredHeight = 0;
      }
      _attachToLoopResizeNest(loop.child, desiredWidth, desiredHeight);
    }
  }

  /// Remove [moving] from the loop referenced by other.child (if present).
  void _detachFromLoopIfAny(BlockModels other, BlockModels moving) {
    if (other.child.isEmpty) return;
    final byId = _byId;
    final loop = byId[other.child];
    if (loop == null) return;
    loop.children.remove(moving.id);

    desiredWidth = 0;
    if (moving.type == 'movement') {
      desiredWidth = 60;
    } else if (moving.type == 'loop') {
      desiredWidth = 148;
    }

    loop.size =
        Size(loop.size.width - desiredWidth, loop.size.height - desiredHeight);
    if (loop.child.isNotEmpty) {
      _detachToLoopResizeNest(loop.child, desiredWidth, desiredHeight);
    }
    desiredHeight = 0;
    noChangeHeightLoops = [];
    moving.child = '';
    parentId = '';
  }

  void _detachToLoopResizeNest(
      String loopId, double desiredWidth, double desiredHeight) {
    final loop = _byId[loopId];
    if (loop == null) return;
    if (loop.child.isNotEmpty) {
      _detachToLoopResizeNest(loop.child, desiredWidth, desiredHeight);
    }
    if (noChangeHeightLoops.contains(loop.id)) {
      desiredHeight = 0;
    }
    loop.size =
        Size(loop.size.width - desiredWidth, loop.size.height - desiredHeight);
    if (loop.rightSnapId.isNotEmpty) {
      _shiftChain(loop.rightSnapId, -desiredWidth);
    }
  }

  /// Shift all direct children of [loopBlock] by dx,dy
  void _shiftChildrenByDelta(BlockModels loopBlock, double dx, double dy) {
    if (loopBlock.children.isEmpty) return;
    final byId = _byId;
    for (final childId in List<String>.from(loopBlock.children)) {
      final child = byId[childId];
      if (child != null) {
        child.position = Offset(child.position.dx + dx, child.position.dy + dy);
      }
    }
  }

  void removeLeftSnapId(String id) {
    final idx = _blocks.indexWhere((b) => b.id == id);
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

  void addBlock(BlockModels item) {
    _blocks.add(item);
    // Use StringBuffer to avoid O(n^2) concatenation if many blocks added.
    _bleBuffer.write(item.bleData);
    notifyListeners();
  }

  void detachBlockFromLoopWidth(String id) {
    final index = _blocks.indexWhere((b) => b.id == id);
    if (index == -1) return;
    if (_blocks[index].child.isEmpty) return;

    final byId = _byId;
    final loopBlock = byId[_blocks[index].child];

    if (loopBlock == null) {
      _blocks[index].child = '';
      return;
    }

    loopBlock.children.remove(_blocks[index].id);

    String currentId = _blocks[index].rightSnapId;
    double sumWidths = 0;
    if (_blocks[index].type == 'loop' &&
        _blocks[index].leftSnapId == loopBlock.id) {
      sumWidths = _blocks[index].size.width - 70;
    } else if (_blocks[index].type == 'movement' &&
        _blocks[index].leftSnapId == loopBlock.id) {
      sumWidths = 0.0;
    } else if (_blocks[index].type == 'movement')
      sumWidths = _blocks[index].size.width - 1;
    else if (_blocks[index].type == 'loop') {
      sumWidths = _blocks[index].size.width - 10;
    }

    // accumulate once and clear child refs
    while (currentId.isNotEmpty && currentId != loopBlock.id) {
      final chained = byId[currentId];
      if (chained == null) break;
      if (chained.type == 'movement')
        sumWidths = sumWidths + (chained.size.width - 1);
      else if (chained.type == 'loop') {
        sumWidths = sumWidths + (chained.size.width - 10);
      }
      chained.child = '';
      loopBlock.children.remove(currentId);
      currentId = chained.rightSnapId;
    }

    final double newWidth =
        (loopBlock.size.width - sumWidths).clamp(0.0, double.infinity);

    loopBlock.size = Size(newWidth, loopBlock.size.height);

    // shift chains with local byId
    if (loopBlock.child.isNotEmpty) {
      detachBlockFromLoopResize(loopBlock.child, sumWidths);
    }
    _shiftChain(loopBlock.rightSnapId, -sumWidths);

    _blocks[index].child = '';
    adjustLoopHeightAfterDetach(loopBlock);
    notifyListeners();
  }

  void detachBlockFromLoopResize(String id, double changeWidth) {
    final loopBlock = _byId[id];
    if (loopBlock == null) return;
    _shiftChain(loopBlock.rightSnapId, -changeWidth);
    loopBlock.size =
        Size(loopBlock.size.width - changeWidth, loopBlock.size.height);
    if (loopBlock.child.isNotEmpty) {
      detachBlockFromLoopResize(loopBlock.child, changeWidth);
    }
  }

  void adjustLoopHeightAfterDetach(BlockModels loopBlock) {
    double chainLoopHeight = 0;
    for (final childId in List<String>.from(loopBlock.children)) {
      final child = _byId[childId];
      if (child == null) continue;
      if (child.type == 'loop') {
        if (child.size.height > chainLoopHeight) {
          chainLoopHeight = child.size.height;
        }
      }
    }
    if (chainLoopHeight != 0) {
      chainLoopHeight = chainLoopHeight + 15;
      loopBlock.size = Size(loopBlock.size.width, chainLoopHeight);
    } else if (chainLoopHeight == 0) {
      loopBlock.size = Size(loopBlock.size.width, 75);
    }
    if (loopBlock.child != '') {
      final parentLoop = _byId[loopBlock.child];
      if (parentLoop != null) adjustLoopHeightAfterDetach(parentLoop);
    }
  }

  void updatePositionById(String id, Offset newPos) {
    final index = _blocks.indexWhere((b) => b.id == id);
    if (index == -1) return;

    if (_blocks[index].leftSnapId.isEmpty) {
      chainWidth = 0;
      chainHeight = 0;
      if (_blocks[index].type == 'loop') {
        chainHeight = _blocks[index].size.height;
      }
      if (_blocks[index].type == 'loop' && _blocks[index].size.width > 158) {
        chainWidth = _blocks[index].size.width - 158;
      }
      final currentBlock = _blocks[index];
      final movingPosition = currentBlock.position;
      final dxChange = movingPosition.dx - newPos.dx;
      final dyChange = movingPosition.dy - newPos.dy;

      // Map for O(1) lookup
      final Map<String, BlockModels> byId = _byId;

      // small helpers (use local closures to avoid repeated allocations)
      void shiftBlock(BlockModels b) {
        b.position = b.position.translate(-dxChange, -dyChange);
      }

      void moveChildrenIfLoop(BlockModels loopBlock) {
        if (loopBlock.type == 'loop' && loopBlock.children.isNotEmpty) {
          for (final childId in List<String>.from(loopBlock.children)) {
            final child = byId[childId];
            if (child?.type == 'loop') {
              moveChildrenIfLoop(child!);
            }
            if (child != null) shiftBlock(child);
          }
        }
      }

      // Move children of the currently dragged block (if loop), then place the block
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
          chainWidth = (chainWidth ?? 0) + next.size.width - 10;
          if (next.size.height > chainHeight!) chainHeight = next.size.height;
        }

        currentId = next.id;
        currentRightSnapId = next.rightSnapId;
      }
      chainRightID = currentId;
    }
    if (chainHeight != 0) chainHeight = chainHeight! - 60;
    // call shadowAnimation and notify once
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
    chainWidth = 0;
    chainHeight = 0;
    chainRightID = '';
    shadowAnimation(1, updatedBlock);
    notifyListeners();
  }

  void _attachToLoopIfAnyLeftInner(BlockModels loop, BlockModels moving) {
    // if (!loop.children.contains(moving.id)) {
    //   loop.children.add(moving.id);
    // }
    double desiredWidth = 0;
    desiredHeight = 0;
    if (moving.type == 'movement' && loop.innerLoopLeftSnapId.isNotEmpty) {
      desiredWidth = 60;
    } else if (moving.type == 'loop') {
      if (loop.children.isNotEmpty) {
        desiredWidth = 148;
      } else {
        desiredWidth = 88;
      }
      if (loop.size.height > 75) {
        desiredHeight = 0;
      } else {
        desiredHeight = 15;
      }
    }
    double tempHeight = desiredHeight;
    loop.size =
        Size(loop.size.width + desiredWidth, loop.size.height + desiredHeight);
    if (loop.child.isNotEmpty) {
      final loopParent = _byId[loop.child];
      if (loopParent == null) return;
      if (loop.size.height + 15 <= loopParent.size.height) {
        desiredHeight = 0;
      }
      _attachToLoopResizeNest(loop.child, desiredWidth, desiredHeight);
    }
    desiredHeight = tempHeight;
    moving.child = loop.id;
    parentId = loop.id;
  }

  void _detachFromLoopIfAnyLeftInner(BlockModels loop, BlockModels moving) {
    // loop.children.remove(moving.id);
    double desiredWidth = 0;
    if (moving.type == 'movement' && loop.innerLoopLeftSnapId.isNotEmpty) {
      desiredWidth = 60;
    } else if (moving.type == 'loop') {
      if (loop.children.isNotEmpty) {
        desiredWidth = 148;
      } else {
        desiredWidth = 88;
      }
    }

    loop.size =
        Size(loop.size.width - desiredWidth, loop.size.height - desiredHeight);
    if (loop.child.isNotEmpty) {
      _detachToLoopResizeNest(loop.child, desiredWidth, desiredHeight);
    }
    desiredHeight = 0;
    noChangeHeightLoops = [];
    moving.child = '';
    parentId = '';
  }

  void loopOverResizeAllLoopIn(String loopId, double width, double height) {
    final parentLoop = _byId[loopId];
    if (parentLoop == null) return;
    _shiftChain(parentLoop.rightSnapId, width);
    parentLoop.size =
        Size(parentLoop.size.width + width, parentLoop.size.height + height);
    if (parentLoop.child.isNotEmpty) {
      final nextParentLoop = _byId[parentLoop.child];
      if (parentLoop.size.height < nextParentLoop!.size.height) {
        height = 0;
        noChangeHeightLoops.add(nextParentLoop.id);
      }

      loopOverResizeAllLoopIn(parentLoop.child, width, height);
    }
  }

  void loopOverResizeAllLoopOut(String loopId, double width, double height) {
    final parentLoop = _byId[loopId];
    if (parentLoop == null) return;
    _shiftChain(parentLoop.rightSnapId, width);
    parentLoop.size =
        Size(parentLoop.size.width + width, parentLoop.size.height + height);
    if (parentLoop.child.isNotEmpty) {
      final nextParentLoop = _byId[parentLoop.child];
      if (noChangeHeightLoops.contains(nextParentLoop!.id)) {
        height = 0;
      }

      loopOverResizeAllLoopOut(parentLoop.child, width, height);
    }
  }

  double heightLoopOverAnimation = 0;
  void shadowAnimation(int idx, BlockModels? block) {
    final moving = block ?? _blocks[idx];
    var mr = moving.rightConnectorAnimation();
    var ml = moving.leftConnectorAnimation();
    if (moving.type == 'loop') {
      mr = moving.rightConnectorLoop();
      ml = moving.leftConnectorLoop();
    }

    final byId = _byId;

    // Local flag to ensure one notify at the end if we changed something
    bool changed = false;

    for (int j = 0; j < _blocks.length; j++) {
      final other = _blocks[j];

      var ol = other.leftConnectorAnimation();
      var or = other.rightConnectorAnimation();
      if (other.type == 'loop') {
        ol = other.leftConnectorLoop();
        or = other.rightConnectorLoop();
        final loopConn = other.ConnectorInLoop();
        if ((ml - loopConn).distance < 35 &&
            other.animationType.isEmpty &&
            !animationFlag &&
            (moving.children.isNotEmpty ||
                other.children.isEmpty ||
                moving.rightSnapId.isNotEmpty)) {
          other.animationType = moving.type;
          animationFlag = true;
          animationSnapId = other.id;
          _attachToLoopIfAnyLeftInner(other, moving);
          if (other.innerLoopLeftSnapId != '') {
            double shiftAmount = 0;
            if (moving.type == 'loop') {
              shiftAmount = 148;
            } else if (moving.type == 'movement') {
              shiftAmount = 60;
            }
            _shiftChain(other.innerLoopLeftSnapId, shiftAmount);
          }
          if (other.rightSnapId != '') {
            double shiftAmount = 0;
            if (moving.type == 'loop') {
              if (other.innerLoopLeftSnapId.isEmpty)
                shiftAmount = 88;
              else
                shiftAmount = 148;
            } else if (moving.type == 'movement') {
              if (other.innerLoopLeftSnapId.isNotEmpty) shiftAmount = 60;
            }
            // }
            _shiftChain(other.rightSnapId, shiftAmount);
          }
          other.animationSide = 'leftInner';
          changed = true;
          break;
        }
        if ((ml - loopConn).distance > 35 &&
            other.animationType.isNotEmpty &&
            other.animationSide == 'leftInner' &&
            (moving.children.isNotEmpty ||
                other.children.isEmpty ||
                moving.rightSnapId.isNotEmpty)) {
          _detachFromLoopIfAnyLeftInner(other, moving);
          if (other.innerLoopLeftSnapId != '') {
            double shiftAmount = 0;
            if (moving.type == 'loop') {
              shiftAmount = 148;
            } else if (moving.type == 'movement') {
              shiftAmount = 60;
            }
            _shiftChain(other.innerLoopLeftSnapId, -shiftAmount);
          }
          if (other.rightSnapId != '') {
            double shiftAmount = 0;
            // if (other.innerLoopLeftSnapId != '') {
            if (moving.type == 'loop') {
              if (other.innerLoopLeftSnapId.isEmpty)
                shiftAmount = 88;
              else
                shiftAmount = 148;
            } else if (moving.type == 'movement') {
              if (other.innerLoopLeftSnapId.isNotEmpty) shiftAmount = 60;
            }
            // }
            _shiftChain(other.rightSnapId, -shiftAmount);
          }
          other.animationType = '';
          animationFlag = false;
          animationSnapId = '';
          other.animationSide = '';
          changed = true;
          break;
        }
      }
      if (moving.type == 'loop') {
        if ((ol - ml).distance < 30 &&
            (ol - ml).distance != 0 &&
            other.animationType.isEmpty &&
            !animationFlag &&
            moving.children.isEmpty &&
            moving.rightSnapId.isEmpty) {
          other.animationType = moving.type;
          animationFlag = true;
          animationSnapId = other.id;
          other.animationSide = 'loopOver';
          noChangeHeightLoops = [];
          if (other.type == 'loop') {
            loopOverWidth = other.size.width + 88;
            loopOverHeight = other.size.height;
          }
          if (other.type == 'loop' && other.rightSnapId.isEmpty) {
            loopOverHeight = other.size.height + 15;
          }
          heightLoopOverAnimation = 15;

          if (other.leftSnapId.isNotEmpty) {
            other.position = Offset(
              other.position.dx + 32,
              other.position.dy,
            );
            if (other.innerLoopLeftSnapId.isNotEmpty) {
              _shiftChain(other.innerLoopLeftSnapId, 32);
            }
            _shiftChainLoopOver(other.rightSnapId, 32);
          } else {
            _shiftChainLoopOver(other.rightSnapId, 0);
          }
          if (other.child.isNotEmpty) {
            final parentLoop = _byId[other.child];
            // if (other.size.height + 15 < parentLoop!.size.height &&
            //     other.type == 'loop') {
            //   print(heightLoopOverAnimation);
            // }

            if (loopOverHeight < parentLoop!.size.height) {
              heightLoopOverAnimation = 0;
            }

            loopOverResizeAllLoopIn(other.child, 88, heightLoopOverAnimation);
          }
          changed = true;
          break;
        }
        if ((ol - ml).distance > 48 &&
            (ol - ml).distance != 0 &&
            other.animationType.isNotEmpty &&
            other.animationSide == 'loopOver' &&
            moving.children.isEmpty &&
            moving.rightSnapId.isEmpty) {
          other.animationType = '';
          animationFlag = false;
          animationSnapId = '';
          other.animationSide = '';
          loopOverWidth = 158;
          loopOverHeight = 75;
          if (other.leftSnapId.isNotEmpty) {
            other.position = Offset(
              other.position.dx - 32,
              other.position.dy,
            );
            if (other.child.isNotEmpty) {
              loopOverResizeAllLoopOut(
                  other.child, -88, -heightLoopOverAnimation);
            }
            if (other.innerLoopLeftSnapId.isNotEmpty) {
              _shiftChain(other.innerLoopLeftSnapId, -32);
            }
            _shiftChain(other.rightSnapId, -32);
          }
          noChangeHeightLoops = [];
          changed = true;
          break;
        }
      }
      // LEFT snap
      if ((mr - ol).distance < snapThreshold &&
          other.animationType.isEmpty &&
          !animationFlag &&
          other.leftSnapId == '') {
        other.animationType = moving.type;
        animationFlag = true;
        animationSnapId = other.id;
        other.animationSide = 'left';
        changed = true;
        break;
      }
      if ((mr - ol).distance > snapThreshold &&
          other.animationType.isNotEmpty &&
          other.animationSide == 'left') {
        other.animationType = '';
        other.animationSide = '';
        animationFlag = false;
        animationSnapId = '';
        changed = true;
        break;
      }

      // RIGHT snap
      if ((ml - or).distance < snapThreshold &&
          other.animationType.isEmpty &&
          !animationFlag &&
          (moving.children.isNotEmpty ||
              other.rightSnapId.isEmpty ||
              moving.rightSnapId.isNotEmpty)) {
        other.animationType = moving.type;
        animationFlag = true;
        _attachToLoopIfAny(other, moving);

        if (other.rightSnapId.isNotEmpty) {
          if (desiredWidth == 0 || other.child.isEmpty) {
            desiredWidth = _shiftAmountForMoving(moving);
          }
          _shiftChain(other.rightSnapId, desiredWidth);
        }
        if (other.child != '') {
          final loop = byId[other.child];
          if (loop?.rightSnapId != '') {
            _shiftChain(loop!.rightSnapId, desiredWidth);
          }
        }

        other.animationSide = 'right';
        animationSnapId = other.id;
        if (other.type == 'loop') {
          loopIdForWidthAnimation = other.id;
        }
        changed = true;
        break;
      }

      if ((ml - or).distance > snapThreshold &&
          other.animationType.isNotEmpty &&
          other.animationSide == 'right' &&
          (moving.children.isNotEmpty ||
              other.rightSnapId.isEmpty ||
              moving.rightSnapId.isNotEmpty)) {
        other.animationType = '';
        other.animationSide = '';
        _detachFromLoopIfAny(other, moving);

        if (other.rightSnapId != '') {
          _shiftChain(other.rightSnapId, -desiredWidth);
        }
        if (other.child != '') {
          final loop = byId[other.child];
          if (loop?.rightSnapId != '') {
            _shiftChain(loop!.rightSnapId, -desiredWidth);
          }
        }
        desiredWidth = 0;
        animationFlag = false;
        animationSnapId = '';
        if (other.type == 'loop') {
          loopIdForWidthAnimation = other.id;
        }
        changed = true;
        break;
      }
    } // end for

    if (changed) notifyListeners();
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

    // LEFT INNER snap
    if (snapBlock.animationSide == 'leftInner') {
      final oldPos = movingBlock.position;
      if (movingBlock.type == 'movement') {
        movingBlock.position = Offset(
          sl.dx + 29,
          sl.dy + 49.5,
        );
      } else if (movingBlock.type == 'loop') {
        movingBlock.position = Offset(
          sl.dx + 29,
          sl.dy + 50,
        );
      }
      parentId = '';
      movingBlock.child = snapBlock.id;
      snapBlock.children.add(movingBlock.id);
      movingBlock.leftSnapId = snapBlock.id;

      final dxChange = movingBlock.position.dx - oldPos.dx;
      final dyChange = movingBlock.position.dy - oldPos.dy;

      if (snapBlock.rightSnapId.isNotEmpty) {
        _shiftChain(snapBlock.rightSnapId, chainWidth!);
        // rightId = snapBlock.rightSnapId;
      }
      final chainRightBlock =
          movingBlock.rightSnapId.isNotEmpty ? byId[chainRightID] : movingBlock;
      if (movingBlock.rightSnapId.isNotEmpty) {
        // snapBlock.size =
        //     Size(snapBlock.size.width + chainWidth!, snapBlock.size.height);

        _shiftChainSnap(movingBlock.rightSnapId, dxChange, dyChange);
        _snapChainLoop(movingBlock.rightSnapId, snapBlock);
      }
      if (snapBlock.innerLoopLeftSnapId != '') {
        _shiftChain(snapBlock.innerLoopLeftSnapId, chainWidth!);
        final firstBlockInLoop = byId[snapBlock.innerLoopLeftSnapId];
        firstBlockInLoop?.leftSnapId = chainRightBlock!.id;
        chainRightBlock?.rightSnapId = snapBlock.innerLoopLeftSnapId;
      }

      double resizeHeight = findGreatestHeightLoop(snapBlock);
      snapBlock.size = Size(snapBlock.size.width + chainWidth!,
          snapBlock.size.height + resizeHeight);
      if (snapBlock.child.isNotEmpty) {
        final parentLoop = _byId[snapBlock.child];
        if (parentLoop!.size.height <= snapBlock.size.height) {
          resizeHeight = snapBlock.size.height - parentLoop.size.height + 15;
        }
        if (parentLoop.size.height > snapBlock.size.height) resizeHeight = 0;
        adjustLoopResizeNest(snapBlock.child, chainWidth!, resizeHeight);
      }
      _ensureChildrenCopyAndForEach(
          movingBlock,
          (childId) =>
              _shiftChainSnapInsideLoop(childId, dxChange, dyChange, byId));
      snapBlock.innerLoopLeftSnapId = movingBlock.id;

      snapBlock.animationType = '';
      snapBlock.animationSide = '';
      animationFlag = false;
      animationSnapId = '';
      desiredHeight = 0;
      desiredWidth = 0;
      noChangeHeightLoops = [];
      notifyListeners();
      return;
    }

    // RIGHT snap
    if (snapBlock.animationSide == 'right') {
      final oldPos = movingBlock.position;
      String rightId = '';
      if (snapBlock.rightSnapId.isNotEmpty && chainWidth != null) {
        _shiftChain(snapBlock.rightSnapId, chainWidth!);
        rightId = snapBlock.rightSnapId;
      }
      if (snapBlock.child != '') {
        final loop = byId[snapBlock.child];
        if (loop != null && chainWidth != null) {
          loop.size = Size(loop.size.width + chainWidth!, loop.size.height);
          _snapChainLoop(movingBlock.rightSnapId, loop);
          if (loop.rightSnapId.isNotEmpty) {
            _shiftChain(loop.rightSnapId, chainWidth!);
          }
          if (loop.child.isNotEmpty) {
            adjustLoopResizeNest(loop.child, chainWidth!, 0);
          }
        }
      }
      if (movingBlock.type == 'movement') {
        movingBlock.leftSnapId = snapBlock.id;
        snapBlock.rightSnapId = movingBlock.id;
        if (movingBlock.child != '') parentId = '';
        if (snapBlock.type == 'movement') {
          movingBlock.position = Offset(
            sr.dx - 1,
            sr.dy,
          );
        } else if (snapBlock.type == 'loop') {
          movingBlock.position = Offset(
            sr.dx + 1.8,
            sr.dy + 50,
          );
        }
        if (movingBlock.rightSnapId.isNotEmpty) {
          final dxChange = movingBlock.position.dx - oldPos.dx;
          final dyChange = movingBlock.position.dy - oldPos.dy;
          _shiftChainSnap(movingBlock.rightSnapId, dxChange, dyChange);
        }
      } else if (movingBlock.type == 'loop') {
        movingBlock.leftSnapId = snapBlock.id;
        snapBlock.rightSnapId = movingBlock.id;
        if (movingBlock.child != '') parentId = '';
        if (snapBlock.type == 'movement') {
          movingBlock.position = Offset(
            sr.dx - 1,
            sr.dy,
          );
        } else if (snapBlock.type == 'loop') {
          movingBlock.position = Offset(
            sr.dx + 1.5,
            sr.dy + 50,
          );
        }
        final dxChange = movingBlock.position.dx - oldPos.dx;
        final dyChange = movingBlock.position.dy - oldPos.dy;
        if (movingBlock.children.isNotEmpty) {
          _ensureChildrenCopyAndForEach(
              movingBlock,
              (childId) =>
                  _shiftChainSnapInsideLoop(childId, dxChange, dyChange, byId));
        }
        if (movingBlock.rightSnapId.isNotEmpty) {
          _shiftChainSnap(movingBlock.rightSnapId, dxChange, dyChange);
        }
      }

      if (rightId.isNotEmpty) {
        final rightSnapBlock = _byId[rightId];
        final otherChainFirstBlock =
            chainRightID.isNotEmpty ? _byId[chainRightID] : movingBlock;
        if (rightSnapBlock != null && otherChainFirstBlock != null) {
          rightSnapBlock.leftSnapId = otherChainFirstBlock.id;
          otherChainFirstBlock.rightSnapId = rightSnapBlock.id;
        }
      }
      if (snapBlock.child != '') {
        final loop = byId[snapBlock.child];
        if (loop != null) {
          double resizeHeight = findGreatestHeightLoop(loop);
          loop.size = Size(loop.size.width, loop.size.height + resizeHeight);
          if (loop.child.isNotEmpty) {
            final parentLoop = _byId[loop.child];
            if (parentLoop!.size.height <= loop.size.height) {
              resizeHeight = loop.size.height - parentLoop.size.height + 15;
            }
            if (loop.size.height < parentLoop.size.height) resizeHeight = 0;
            adjustLoopResizeNest(loop.child, 0, resizeHeight);
          }
        }
      }
      snapBlock.animationType = '';
      snapBlock.animationSide = '';
      animationFlag = false;
      animationSnapId = '';
      chainWidth = 0;
      desiredHeight = 0;
      desiredWidth = 0;
      noChangeHeightLoops = [];
      notifyListeners();
      return;
    }

    // LEFT snap
    if (snapBlock.animationSide == 'left') {
      if (movingBlock.type == 'movement') {
        movingBlock.rightSnapId = snapBlock.id;
        snapBlock.leftSnapId = movingBlock.id;
        if (snapBlock.type == 'movement') {
          movingBlock.position = Offset(
            sl.dx - movingBlock.size.width + 1,
            sl.dy,
          );
        } else if (snapBlock.type == 'loop') {
          movingBlock.position = Offset(
            sl.dx - movingBlock.size.width - 0.5,
            sl.dy + 50,
          );
        }
      } else if (movingBlock.type == 'loop') {
        movingBlock.rightSnapId = snapBlock.id;
        snapBlock.leftSnapId = movingBlock.id;
        final oldPos = movingBlock.position;
        if (snapBlock.type == 'movement') {
          movingBlock.position = Offset(
            sl.dx - movingBlock.size.width + 10,
            sl.dy,
          );
        } else if (snapBlock.type == 'loop') {
          movingBlock.position = Offset(
            sl.dx - movingBlock.size.width + 10,
            sr.dy + 50,
          );
        }

        final dxChange = movingBlock.position.dx - oldPos.dx;
        final dyChange = movingBlock.position.dy - oldPos.dy;
        if (movingBlock.children.isNotEmpty) {
          for (final childId in List<String>.from(movingBlock.children)) {
            final child = byId[childId];
            if (child != null) {
              child.position = Offset(
                  child.position.dx + dxChange, child.position.dy + dyChange);
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
    if (snapBlock.animationSide == 'loopOver') {
      if (snapBlock.type == 'movement') {
        movingBlock.position = Offset(
          sl.dx - 31,
          sl.dy,
        );
        movingBlock.size = Size(loopOverWidth, loopOverHeight);
      } else if (snapBlock.type == 'loop') {
        movingBlock.size = Size(loopOverWidth, loopOverHeight);
        movingBlock.position = Offset(
          sl.dx - 33,
          sl.dy + 50,
        );
      }
      if (snapBlock.child.isEmpty) {
        if (snapBlock.leftSnapId.isNotEmpty) {
          final leftBlock = byId[snapBlock.leftSnapId];
          leftBlock!.rightSnapId = movingBlock.id;
          movingBlock.leftSnapId = leftBlock.id;
        }
        snapBlock.leftSnapId = movingBlock.id;
        movingBlock.innerLoopLeftSnapId = snapBlock.id;
      }
      _addChildrenLoopOver(snapBlock.id, movingBlock.id);
      // final loopOverRightID =
      //
      // if (loopOverRightID != snapBlock.id) {
      //   final loopOverRightBlock = _byId[loopOverRightID];
      //   // loopOverRightBlock!.rightSnapId = movingBlock.id;
      // } else {
      //   // snapBlock.rightSnapId = movingBlock.id;
      // }

      chainWidth = 0;
      loopOverWidth = 158;
      loopOverHeight = 75;
      snapBlock.animationType = '';
      snapBlock.animationSide = '';
      animationFlag = false;
      animationSnapId = '';
      bringChainToFront(movingBlock.id);
      notifyListeners();
      return;
    }
  }

  String _addChildrenLoopOver(String startId, String loopId) {
    if (startId.isEmpty) return '';
    final byId = _byId;
    final loop = byId[loopId];
    if (loop == null) return '';
    var current = startId;
    final block = byId[current];
    if (block!.child.isNotEmpty) {
      final parentLoop = byId[block.child];
      parentLoop!.children.add(loop.id);
      loop.child = parentLoop.id;
      if (block.leftSnapId == parentLoop.id) {
        parentLoop.innerLoopLeftSnapId = loop.id;
        loop.leftSnapId = parentLoop.id;
      } else {
        final leftBlock = byId[block.leftSnapId];
        leftBlock!.rightSnapId = loop.id;
        loop.leftSnapId = leftBlock.id;
      }
      loop.innerLoopLeftSnapId = block.id;
      block.leftSnapId = loop.id;
    }
    String loopOverRightID = current;
    while (current.isNotEmpty) {
      final block = byId[current];
      if (block == null) break;
      loop.children.add(block.id);
      if (block.child.isNotEmpty) {
        final parentLoop = byId[block.child];
        parentLoop!.children.remove(block.id);
      }
      block.child = loop.id;
      loopOverRightID = block.id;
      current = block.rightSnapId;
    }

    return loopOverRightID;
  }

  double findGreatestHeightLoop(BlockModels loop) {
    double height = 0;
    for (final childId in List<String>.from(loop.children)) {
      final child = _byId[childId];
      if (child == null) continue;
      if (child.type == 'loop' && child.size.height > height) {
        height = child.size.height;
      }
    }
    if (height == loop.size.height) {
      height = 15;
    } else if (height < loop.size.height) {
      height = 0;
    } else if (height > loop.size.height) {
      height = height - loop.size.height + 15;
    }
    return height;
  }

  void adjustLoopResizeNest(
      String loopId, double chainWidth, double chainHeight) {
    final loop = _byId[loopId];
    if (loop == null) return;
    _shiftChain(loop.rightSnapId, chainWidth);
    loop.size =
        Size(loop.size.width + chainWidth, loop.size.height + chainHeight);
    if (loop.child.isNotEmpty) {
      adjustLoopResizeNest(loop.child, chainWidth, chainHeight);
    }
  }
}
