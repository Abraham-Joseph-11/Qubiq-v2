import 'package:flutter/material.dart';

class ResizableNineSlice extends StatefulWidget {
  final String assetPath;
  final double initialWidth;
  final double initialHeight;
  final int leftPreserve;
  final int topPreserve;
  final int rightPreserve;
  final int bottomPreserve;

  const ResizableNineSlice({
    super.key,
    required this.assetPath,
    this.initialWidth = 240,
    this.initialHeight = 120,
    this.leftPreserve = 8,
    this.topPreserve = 12,
    this.rightPreserve = 8,
    this.bottomPreserve = 10,
  });

  @override
  _ResizableNineSliceState createState() => _ResizableNineSliceState();
}

class _ResizableNineSliceState extends State<ResizableNineSlice> {
  double width = 240;
  double height = 120;
  Rect? centerSlice;
  late ImageProvider provider;

  @override
  void initState() {
    super.initState();
    width = widget.initialWidth;
    height = widget.initialHeight;
    provider = AssetImage(widget.assetPath);
    _resolveImage();
  }

  void _resolveImage() {
    final stream = provider.resolve(const ImageConfiguration());
    ImageStreamListener? listener;
    listener = ImageStreamListener((ImageInfo info, bool _) {
      final imgW = info.image.width;
      final imgH = info.image.height;
      // compute centerSlice from preserved pixels
      final left = widget.leftPreserve.toDouble();
      final top = widget.topPreserve.toDouble();
      final w = imgW - widget.leftPreserve - widget.rightPreserve;
      final h = imgH - widget.topPreserve - widget.bottomPreserve;
      // keep rect strictly inside image: ensure >= 1
      final rect = Rect.fromLTWH(
          left, top, w > 1 ? w.toDouble() : 1.0, h > 1 ? h.toDouble() : 1.0);
      setState(() => centerSlice = rect);
      // remove listener after first frame
      stream.removeListener(listener!);
    }, onError: (err, stack) {
      // fallback: set a simple rect if asset fails to resolve
      setState(() => centerSlice = Rect.fromLTWH(1, 1, 10, 10));
      stream.removeListener(listener!);
    });
    stream.addListener(listener);
  }

  // handle dragging the bottom-right corner
  void _onDrag(DragUpdateDetails details) {
    setState(() {
      width = (width + details.delta.dx).clamp(40.0, 2000.0);
      height = (height + details.delta.dy).clamp(20.0, 2000.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    // show a simple UI with the resizable panel and a draggable handle
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
            'Panel: ${width.toStringAsFixed(0)} × ${height.toStringAsFixed(0)}'),
        const SizedBox(height: 8),
        Stack(
          children: [
            // animated so resizing looks smooth
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: width,
              height: height,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: provider,
                  fit: BoxFit.fill,
                  centerSlice: centerSlice ?? Rect.fromLTWH(8, 12, 184, 78),
                ),
              ),
            ),
            // draggable handle at bottom-right
            Positioned(
              left: width - 24,
              top: height - 24,
              child: GestureDetector(
                onPanUpdate: _onDrag,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    border: Border.all(),
                    color: Colors.black.withOpacity(0.1),
                  ),
                  child: const Icon(Icons.drag_handle, size: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // optional sliders for precise control (useful for testing)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              children: [
                const Text('Width'),
                Slider(
                  min: 40,
                  max: 1000,
                  value: width,
                  onChanged: (v) => setState(() => width = v),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                const Text('Height'),
                Slider(
                  min: 20,
                  max: 1000,
                  value: height,
                  onChanged: (v) => setState(() => height = v),
                ),
              ],
            )
          ],
        ),
      ],
    );
  }
}
