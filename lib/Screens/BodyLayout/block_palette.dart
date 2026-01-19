import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Providers/block_provider.dart';
import 'BlockPanels/loops.dart';
import 'BlockPanels/movement.dart';

class BlockPalette extends StatefulWidget {
  const BlockPalette({super.key});

  @override
  State<BlockPalette> createState() => _BlockPaletteState();
}

class _BlockPaletteState extends State<BlockPalette> {
  final categories = [
    {'icon': Icons.run_circle, 'color': Colors.blue},
    {'icon': Icons.checkroom, 'color': Colors.purple},
    {'icon': Icons.flag, 'color': Colors.yellow},
    // etc...
  ];

  final Map<int, Widget> _blockpanel = {
    0: const Movement(),
    1: const Loop(),
    2: const Movement(),
  };
  int selectedIndex = 1;
  @override
  Widget build(BuildContext context) {
    final provider = context.read<BlockProvider>();
    return Column(
      children: [
        // category bar
        Container(
          height: 56,
          color: Colors.white,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 8),
            itemCount: categories.length,
            separatorBuilder: (_, __) => SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: categories[i]['color'] as Color,
                  shape: BoxShape.circle,
                  // add a border when selected
                  border: selectedIndex == i
                      ? Border.all(color: Colors.white, width: 2)
                      : null,
                ),
                child: IconButton(
                  icon: Icon(categories[i]['icon'] as IconData),
                  color: Colors.white,
                  iconSize: 20,
                  splashRadius: 24,
                  onPressed: () {
                    setState(() {
                      selectedIndex = i;
                    });
                  },
                ),
              );
            },
          ),
        ),

        // blocks list
        Expanded(
          child: _blockpanel[selectedIndex]!,
        ),
      ],
    );
  }
}
