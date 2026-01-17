import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../../Providers/block_provider.dart';
import '../../Services/bluetooth_manager.dart';

class StageViewer extends StatelessWidget {
  const StageViewer({super.key});

  @override
  Widget build(BuildContext context) {
    final robotPosition = context.watch<BlockProvider>().robotPosition;

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.all(8),
      child: Stack(
        children: [
          // ✅ Zoomable Stage Layer
          InteractiveViewer(
            minScale: 0.2,
            maxScale: 4.0,
            boundaryMargin: const EdgeInsets.all(1000),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final centerX = constraints.maxWidth / 2;
                final centerY = constraints.maxHeight / 2;
                final robotTop = centerY + robotPosition.dy - 50;
                final robotLeft = centerX + robotPosition.dx - 50;

                return SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        top: robotTop,
                        left: robotLeft,
                        child: SvgPicture.asset(
                          './lib/Resources/little_emmi.svg',
                          width: 100,
                          height: 100,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ✅ Fixed UI Layer (Play Button)
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              heroTag: 'run_btn_fixed',
              backgroundColor: Colors.green,
              onPressed: () {
                final bluetooth = context.read<BluetoothManager>();
                context.read<BlockProvider>().runCode(bluetooth);
              },
              child: const Icon(Icons.play_arrow, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}