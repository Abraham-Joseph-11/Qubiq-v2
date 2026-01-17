import 'package:flutter/material.dart';
import 'block_palette.dart';
import '../block_canvastest.dart';
import 'stage_viewer.dart';

class BodyLayout extends StatelessWidget {
  const BodyLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Breakpoint for mobile is 600px
        bool isMobile = constraints.maxWidth < 600;

        return Column(
          children: [
            Expanded(
              flex: 3,
              child: isMobile
                  ? Column( // Stack vertically on mobile
                children: [
                  Expanded(flex: 3, child: BlockCanvas()),
                  const Divider(height: 2, thickness: 2),
                  Expanded(flex: 2, child: StageViewer()),
                ],
              )
                  : Row( // Side-by-side on desktop
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 2, child: BlockCanvas()),
                  const VerticalDivider(width: 2, thickness: 2),
                  Expanded(flex: 1, child: StageViewer()),
                ],
              ),
            ),
            Container(height: 6, color: const Color(0xFFE0E0E0)),
            // Palette stays at bottom
            Expanded(
              flex: 1,
              child: BlockPalette(),
            ),
          ],
        );
      },
    );
  }
}