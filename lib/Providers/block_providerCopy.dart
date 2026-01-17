import 'package:flutter/material.dart';
import '../Models/BlockModels.dart';

class BlockProvider extends ChangeNotifier {
  final List<BlockModels> _blocks = [];
  String bleDataString = '';
  double snapThreshold = 45;

  List<BlockModels> get blocks => _blocks;
  bool animationFlag = false;

  String? chainRightID;
  String? attachLeftID;
  double? chainWidth;
  String? animationSnapId;
  String parentId = '';

  String loopIdForWidthAnimation = ''; // -----------------------

  double loopOverWidth = 158;
  double loopOverHeight = 75;

  /// Construct a temporary id->BlockModels map for O(1) lookups.
  Map<String, BlockModels> get _byId => {for (var b in _blocks) b.id: b};

  double _shiftAmountForMoving(BlockModels moving) {
    if (moving.type == 'movement') return moving.size.width - 1;
    if (moving.type == 'loop') return moving.size.width - 10;
    return 0;
  }

  //
  void bringToFront(String id) {
    final idx = _blocks.indexWhere((blk) => blk.id == id);
    if (idx == -1) return;

    final block = _blocks.removeAt(idx);
    _blocks.add(block);

    if (block.type == 'loop' && block.children.isNotEmpty) {
      // Ensure children is a List<String> (copy before mutating)
      final List<String> childIds = List<String>.from(block.children);

      for (final childId in childIds) {
        final idxChild = _blocks.indexWhere((blk) => blk.id == childId);
        if (idxChild == -1) continue; // skip missing children
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

  /// Shift the chain starting from [startId] by dx horizontally.
  void _shiftChain(String startId, double dx) {
    var byId = _byId;
    var current = startId;

    while (current.isNotEmpty) {
      final block = byId[current];
      if (block == null) break;

      // Shift this block
      block.position = Offset(block.position.dx + dx, block.position.dy);

      // If it's a loop, shift all its children (recursively)
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

    // Move to the next block in the chain
  }

  void _shiftChainSnap(String startId, double dx, double dy) {
    var byId = _byId;
    var current = startId;

    while (current.isNotEmpty) {
      final block = byId[current];
      if (block == null) break;

      // Shift this block
      block.position = Offset(block.position.dx + dx, block.position.dy + dy);

      // If it's a loop, shift all its children (recursively)
      if (block.type == 'loop') {
        for (var childID in block.children) {
          _shiftChainSnapInsideLoop(childID, dx, dy);
        }
      }

      // Move to the next block in the chain
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

    // Move to the next block in the chain
  }

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

  /// Add [moving] as a child of the loop referenced by other.child (if present).
  void _attachToLoopIfAny(BlockModels other, BlockModels moving) {
    if (other.child == '') return;
    final loop = _byId[other.child];
    if (loop == null) return;

    // add child if not already there
    if (!loop.children.contains(moving.id)) {
      loop.children.add(moving.id);
    }
    final length = loop.children.length;
    final desiredWidth = 158 + (60 * (length - 1));
    loop.size = Size(desiredWidth.toDouble(), loop.size.height);
    moving.child = loop.id;
    parentId = loop.id;
  }

  /// Remove [moving] from the loop referenced by other.child (if present).
  void _detachFromLoopIfAny(BlockModels other, BlockModels moving) {
    if (other.child == '') return;
    final loop = _byId[other.child];
    if (loop == null) return;

    // remove child if present
    loop.children.remove(moving.id);

    final length = loop.children.length;
    final desiredWidth = 158 + (60 * (length - 1));
    loop.size = Size(desiredWidth.toDouble(), loop.size.height);
    // clear parent reference
    moving.child = '';
    parentId = '';
  }

  /// Shift all direct children of [loopBlock] by dx,dy
  void _shiftChildrenByDelta(BlockModels loopBlock, double dx, double dy) {
    if (loopBlock.children.isEmpty) return;
    final copy = List<String>.from(loopBlock.children);
    final byId = _byId;
    for (final childId in copy) {
      final child = byId[childId];
      if (child != null) {
        child.position = Offset(child.position.dx + dx, child.position.dy + dy);
      }
    }
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

  void addBlock(BlockModels item) {
    _blocks.add(item);
    bleDataString = bleDataString + item.bleData;
    notifyListeners();
  }

  void detachBlockFromLoopWidth(String id) {
    final index = blocks.indexWhere((b) => b.id == id);
    if (_blocks[index].child == '') return;
    final byId = _byId; // Map<String, BlockModels>
    final loopBlock = byId[_blocks[index].child];
    if (loopBlock == null) {
      _blocks[index].child = '';
      return;
    }

    // remove this block from loop children (if present)
    loopBlock.children.remove(_blocks[index].id);

    // traverse the right-chain starting from the block's rightSnapId
    String currentId = _blocks[index].rightSnapId;
    double sumWidths = 60;
    if (_blocks[index].leftSnapId == loopBlock.id) {
      sumWidths = 0.0;
    }

    while (currentId.isNotEmpty && currentId != loopBlock.id) {
      final chained = byId[currentId];
      if (chained == null) break; // safety
      sumWidths = sumWidths + (chained.size.width - 1);
      chained.child = '';
      loopBlock.children.remove(currentId);
      currentId = chained.rightSnapId;
    }

    // subtract directly (user assured sumWidths <= loop width); clamp to >= 0 as a safety
    final double newWidth = loopBlock.size.width - sumWidths;
    loopBlock.size = Size(newWidth, loopBlock.size.height);
    _shiftChain(loopBlock.rightSnapId, -sumWidths);
    // clear the child link on the detached block
    _blocks[index].child = '';
  }

  void updatePositionById(String id, Offset newPos) {
    final index = blocks.indexWhere((b) => b.id == id);
    if (index == -1) return;

    // detachBlockFromLoopWidth(index);
    // Only perform chain movement when the block has no left snap (free-moving)
    if (_blocks[index].leftSnapId.isEmpty) {
      chainWidth = 0;
      final currentBlock = _blocks[index];
      final movingPosition = currentBlock.position;
      final dxChange = movingPosition.dx - newPos.dx;
      final dyChange = movingPosition.dy - newPos.dy;

      // Map for O(1) lookup
      final Map<String, BlockModels> byId = _byId;

      // small helpers (keep the same sign as original code)
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

      // Move children of the currently dragged block (if loop), then place the block
      moveChildrenIfLoop(currentBlock);
      currentBlock.position = newPos;
      // Walk the chain of right-snap blocks using the map
      var currentRightSnapId = currentBlock.rightSnapId;
      var currentId = currentBlock.id;

      while (currentRightSnapId.isNotEmpty) {
        final next = byId[currentRightSnapId];
        if (next == null) break; // no block with that id — stop
        // sanity check: ensure the chain is consistent (next's leftSnap should point back)
        if (next.leftSnapId != currentId) break;

        // If next is a loop, shift its children first
        moveChildrenIfLoop(next);

        // Shift this linked block to maintain relative offset
        shiftBlock(next);
        if (next.type == 'movement') {
          chainWidth = (chainWidth ?? 0) + next.size.width - 1;
        } else if (next.type == 'loop') {
          chainWidth = (chainWidth ?? 0) + next.size.width - 11;
        }
        // advance
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
        if ((ml - loopConn).distance < 35 &&
            other.animationType.isEmpty &&
            !animationFlag) {
          other.animationType = moving.type;
          animationFlag = true;
          animationSnapId = other.id;
          if (moving.type == 'loop') {
            other.size = Size(other.size.width + 100, other.size.height + 16);
          }
          if (other.innerLoopLeftSnapId != '') {
            final shiftAmount = _shiftAmountForMoving(moving);
            _shiftChain(other.innerLoopLeftSnapId, shiftAmount);
            other.size =
                Size(other.size.width + shiftAmount, other.size.height);
          }
          if (other.rightSnapId != '' && other.innerLoopLeftSnapId != '') {
            final shiftAmount = _shiftAmountForMoving(moving);
            _shiftChain(other.rightSnapId, shiftAmount);
          }
          other.animationSide = 'leftInner';
          notifyListeners();
          return;
        }
        //
        if ((ml - loopConn).distance > 35 &&
            other.animationType.isNotEmpty &&
            other.animationSide == 'leftInner') {
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
            other.size =
                Size(other.size.width - shiftAmount, other.size.height);
          }
          if (other.rightSnapId != '' && other.innerLoopLeftSnapId != '') {
            final shiftAmount = _shiftAmountForMoving(moving);
            _shiftChain(other.rightSnapId, -shiftAmount);
          }
          notifyListeners();
          return;
        }
      }
      // left snap (moving.right -> other.left)
      if ((mr - ol).distance < snapThreshold &&
          other.animationType.isEmpty &&
          !animationFlag &&
          other.leftSnapId == '') {
        other.animationType = moving.type;
        animationFlag = true;
        animationSnapId = other.id;
        other.animationSide = 'left';
        notifyListeners();
        return;
      }
      if ((mr - ol).distance > snapThreshold &&
          other.animationType.isNotEmpty &&
          other.animationSide == 'left') {
        other.animationType = '';
        other.animationSide = '';
        animationFlag = false;
        animationSnapId = '';
        notifyListeners();
        return;
      }

      // right snap (moving.left -> other.right)
      if ((ml - or).distance < snapThreshold &&
          other.animationType.isEmpty &&
          !animationFlag) {
        other.animationType = moving.type;
        animationFlag = true;
        _attachToLoopIfAny(other, moving);

        // shift any chain to the right of 'other' by the required amount
        if (other.rightSnapId != '') {
          final shiftAmount = _shiftAmountForMoving(moving);
          _shiftChain(other.rightSnapId, shiftAmount);
        }
        if (other.child != '') {
          final loop = _byId[other.child];
          if (loop?.rightSnapId != '') {
            print('loop in');
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

      if ((ml - or).distance > snapThreshold &&
          other.animationType.isNotEmpty &&
          other.animationSide == 'right') {
        other.animationType = '';
        other.animationSide = '';
        _detachFromLoopIfAny(other, moving);

        // shift any chain to the right of 'other' back by -shiftAmount
        if (other.rightSnapId != '') {
          final shiftAmount = _shiftAmountForMoving(moving);
          _shiftChain(other.rightSnapId, -shiftAmount);
        }
        if (other.child != '') {
          final loop = _byId[other.child];
          if (loop?.rightSnapId != '') {
            print('loop out');
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
    // guard against missing animation target or moving block
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
        movingBlock.position = Offset(
          sl.dx + 29,
          sl.dy + 49.5,
        );
        movingBlock.child = snapBlock.id;
        snapBlock.children.add(movingBlock.id);
        movingBlock.leftSnapId = snapBlock.id;
        // clear
        snapBlock.animationType = '';
        snapBlock.animationSide = '';
        animationFlag = false;
        animationSnapId = '';
      } else if (movingBlock.type == 'loop') {
        movingBlock.position = Offset(
          sl.dx + 33,
          sl.dy + 50,
        );
        movingBlock.child = snapBlock.id;
        snapBlock.children.add(movingBlock.id);
        movingBlock.leftSnapId = snapBlock.id;
        // clear
        snapBlock.animationType = '';
        snapBlock.animationSide = '';
        animationFlag = false;
        animationSnapId = '';
      }
      if (snapBlock.rightSnapId.isNotEmpty) {
        print('in move');
        print('width:$chainWidth');
        _shiftChain(snapBlock.rightSnapId, chainWidth!);
        // rightId = snapBlock.rightSnapId;
      }
      final chainRightBlock =
          movingBlock.rightSnapId.isNotEmpty ? byId[chainRightID] : movingBlock;
      if (movingBlock.rightSnapId.isNotEmpty) {
        snapBlock.size =
            Size(snapBlock.size.width + chainWidth!, snapBlock.size.height);
        final dxChange = movingBlock.position.dx - oldPos.dx;
        final dyChange = movingBlock.position.dy - oldPos.dy;
        _shiftChainSnap(movingBlock.rightSnapId, dxChange, dyChange);
        _snapChainLoop(movingBlock.rightSnapId, snapBlock);
      }
      if (snapBlock.innerLoopLeftSnapId != '') {
        _shiftChain(snapBlock.innerLoopLeftSnapId, chainWidth!);
        final firstBlockInLoop = byId[snapBlock.innerLoopLeftSnapId];
        firstBlockInLoop?.leftSnapId = chainRightID!;
        chainRightBlock?.rightSnapId = snapBlock.innerLoopLeftSnapId;
      }
      snapBlock.innerLoopLeftSnapId = movingBlock.id;
      notifyListeners();
      return;
    }
    //
    else if (snapBlock.animationSide == 'right') {
      final oldPos = movingBlock.position;
      String rightId = '';
      if (snapBlock.rightSnapId.isNotEmpty) {
        print('in move');
        print('width:$chainWidth');
        _shiftChain(snapBlock.rightSnapId, chainWidth!);
        rightId = snapBlock.rightSnapId;
      }
      if (snapBlock.child != '') {
        final loop = _byId[snapBlock.child];
        loop?.size = Size(loop.size.width + chainWidth!, loop.size.height);
        _snapChainLoop(movingBlock.rightSnapId, loop!);
        if (loop.rightSnapId.isNotEmpty) {
          _shiftChain(loop.rightSnapId, chainWidth!);
        }
      }
      if (movingBlock.type == 'movement') {
        movingBlock.leftSnapId = snapBlock.id;
        snapBlock.rightSnapId = movingBlock.id;
        if (movingBlock.child != '') {
          parentId = '';
        }
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

        if (movingBlock.child != '') {
          parentId = '';
        }
        if (snapBlock.type == 'movement') {
          movingBlock.position = Offset(
            sr.dx - 1,
            sl.dy,
          );
        } else if (snapBlock.type == 'loop') {
          movingBlock.position = Offset(
            sr.dx,
            sr.dy + 50,
          );
        }
        final dxChange = movingBlock.position.dx - oldPos.dx;
        final dyChange = movingBlock.position.dy - oldPos.dy;
        if (movingBlock.children.isNotEmpty) {
          for (final childId in List<String>.from(movingBlock.children)) {
            final child = byId[childId];
            if (child != null) {
              child.position = Offset(child.position.dx + dxChange,
                  child.position.dy + dyChange); //no inside loop case added
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
        rightSnapBlock!.leftSnapId = chainRightID!;
        otherChainFirstBlock?.rightSnapId = rightSnapBlock.id;
      }
      // clear animation markers on snap
      snapBlock.animationType = '';
      snapBlock.animationSide = '';
      animationFlag = false;
      animationSnapId = '';
      chainWidth = 0;
      notifyListeners();
      return;
    }
//
    else if (snapBlock.animationSide == 'left') {
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

        // adjust children by the same delta using map lookup
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

      // clear animation markers on snap
      snapBlock.animationType = '';
      snapBlock.animationSide = '';
      animationFlag = false;
      animationSnapId = '';
      notifyListeners();
      return;
    }
  }
}
