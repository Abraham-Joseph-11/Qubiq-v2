import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:highlight/languages/python.dart';
import 'package:provider/provider.dart';

import 'package:little_emmi/Providers/flowchart_provider.dart';
import 'package:little_emmi/Screens/Flowchart/flowchart_palette.dart';
import 'package:little_emmi/Screens/Flowchart/flowchart_canvas.dart';
import 'package:little_emmi/Models/flow_block_model.dart';
import 'package:little_emmi/Utils/responsive_layout.dart';

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:process_run/shell.dart';
import 'package:path/path.dart' as p;

class FlowchartIdeScreen extends StatelessWidget {
  const FlowchartIdeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FlowchartProvider(),
      child: const _FlowchartIdeView(),
    );
  }
}

class _FlowchartIdeView extends StatefulWidget {
  const _FlowchartIdeView();

  @override
  State<_FlowchartIdeView> createState() => _FlowchartIdeViewState();
}

class _FlowchartIdeViewState extends State<_FlowchartIdeView> {
  final TransformationController _transformationController = TransformationController();
  final _codeController = CodeController(
    language: python,
    text: "# Your flowchart code will appear here...",
  );
  String _terminalOutput = "Output will appear here.";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _transformationController.value = Matrix4.identity()..scale(0.5);
  }

  void _zoom(double factor) {
    setState(() {
      _transformationController.value = _transformationController.value.clone()..scale(factor);
    });
  }

  void _generateAndRunCode() async {
    if (context.read<FlowchartProvider>().currentAnimation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wait for the current execution to finish.')),
      );
      return;
    }
    bool success = await _gatherAllInputs();
    if (!success) return;

    setState(() {
      _isLoading = true;
      _terminalOutput = "Generating and running code...";
    });

    final provider = context.read<FlowchartProvider>();
    final generatedCode = provider.generatePythonCode();
    _codeController.text = generatedCode;

    try {
      Future<String> scriptResultFuture = _runPythonScript(generatedCode);
      await provider.runVisualAnimation();
      _terminalOutput = await scriptResultFuture;
    } catch (e) {
      _terminalOutput = "Failed to run script.\nError: $e";
    }
    setState(() => _isLoading = false);
  }

  Future<bool> _gatherAllInputs() async {
    final provider = context.read<FlowchartProvider>();
    final inputBlocks = provider.blocks.where((b) => b.type == FlowchartBlockType.input).toList();
    for (final block in inputBlocks) {
      final textController = TextEditingController();
      final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Input Required"),
          content: TextField(
            controller: textController,
            decoration: InputDecoration(
              labelText: "Enter value for variable: ${block.content}",
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            TextButton(onPressed: () => Navigator.pop(context, textController.text), child: const Text("OK")),
          ],
        ),
      );
      if (result == null) return false;
      provider.updateBlockInputValue(block.id, result);
    }
    return true;
  }

  Future<String> _runPythonScript(String code) async {
    try {
      String appDirectory = p.dirname(Platform.resolvedExecutable);
      String pythonExePath = p.join(appDirectory, 'python_runtime', 'python.exe');
      final directory = await getTemporaryDirectory();
      final scriptFile = File('${directory.path}/flow_script.py');
      await scriptFile.writeAsString(code);
      var shell = Shell();
      var result = await shell.run('"$pythonExePath" "${scriptFile.path}"');
      return result.first.stdout.isNotEmpty ? result.first.stdout : "Finished.";
    } catch (e) { return "Failed: $e"; }
  }

  void _resetFlowchart() {
    context.read<FlowchartProvider>().clearCanvas();
    setState(() {
      _transformationController.value = Matrix4.identity()..scale(0.5);
      _codeController.text = "";
      _terminalOutput = "Cleared.";
    });
  }

  Widget _buildCodeAndTerminal({required bool isMobile}) {
    return Column(
      children: [
        SizedBox(
          height: isMobile ? 300 : null,
          child: CodeTheme(
            data: CodeThemeData(styles: monokaiSublimeTheme),
            child: CodeField(
              controller: _codeController,
              readOnly: true,
              textStyle: GoogleFonts.robotoMono(fontSize: 12),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          height: isMobile ? 200 : null,
          padding: const EdgeInsets.all(12),
          color: Colors.black,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("TERMINAL", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
              const Divider(color: Colors.white10),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    _terminalOutput,
                    style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Flowchart IDE", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _resetFlowchart,
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.greenAccent),
            onPressed: _generateAndRunCode,
          ),
        ],
      ),
      body: ResponsiveLayout(
        mobileBody: SingleChildScrollView(
          child: Column(
            children: [
              ExpansionTile(
                collapsedBackgroundColor: Colors.grey[850],
                backgroundColor: Colors.grey[850],
                title: const Text("Blocks", style: TextStyle(color: Colors.white)),
                children: [
                  // GestureDetector makes the whole area sensitive to swipes
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      // Adding horizontal margin creates a swipe-safe zone
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const FlowchartPalette(),
                    ),
                  ),
                ],
              ),

              Container(
                height: 500,
                width: double.infinity,
                decoration: const BoxDecoration(border: Border.symmetric(horizontal: BorderSide(color: Colors.white10))),
                child: Stack(
                  children: [
                    InteractiveViewer(
                      transformationController: _transformationController,
                      boundaryMargin: const EdgeInsets.all(1000),
                      minScale: 0.1,
                      maxScale: 2.0,
                      constrained: false,
                      child: const SizedBox(
                        width: 2500,
                        height: 2500,
                        child: FlowchartCanvas(),
                      ),
                    ),
                    Positioned(
                      right: 15,
                      bottom: 15,
                      child: Column(
                        children: [
                          FloatingActionButton.small(
                            heroTag: "btnZoomIn",
                            onPressed: () => _zoom(1.2),
                            child: const Icon(Icons.add),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton.small(
                            heroTag: "btnZoomOut",
                            onPressed: () => _zoom(0.8),
                            child: const Icon(Icons.remove),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              _buildCodeAndTerminal(isMobile: true),
            ],
          ),
        ),
        desktopBody: Row(
          children: [
            Container(width: 200, color: Colors.grey[850], child: const FlowchartPalette()),
            const Expanded(flex: 3, child: FlowchartCanvas()),
            SizedBox(width: 350, child: _buildCodeAndTerminal(isMobile: false)),
          ],
        ),
      ),
    );
  }
}