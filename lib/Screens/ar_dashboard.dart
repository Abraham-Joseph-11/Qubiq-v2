import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

// Conditional import to prevent compilation errors on non-Windows platforms
// Ideally, you would use separate files, but for a single file solution:
import 'package:webview_windows/webview_windows.dart' as win;

class ARDashboard extends StatefulWidget {
  const ARDashboard({super.key});

  @override
  State<ARDashboard> createState() => _ARDashboardState();
}

class _ARDashboardState extends State<ARDashboard> {
  List allSubjects = [];
  List filteredSubjects = [];
  bool loading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    // 1. Load Local Data
    try {
      // Create a dummy assets/curriculum.json if you don't have one to prevent crash
      final jsonString = await rootBundle.loadString('assets/curriculum.json');
      final localData = json.decode(jsonString);
      if (mounted) {
        setState(() {
          allSubjects = List.from(localData['subjects']);
          filteredSubjects = allSubjects;
        });
      }
    } catch (e) {
      debugPrint("Local load error (ensure assets/curriculum.json exists): $e");
      // Fallback empty data so the app doesn't look broken
      if (mounted) {
        setState(() {
          allSubjects = [];
          filteredSubjects = [];
        });
      }
    }

    // 2. Load NASA Data
    try {
      final nasaSearchResponse = await http.get(
          Uri.parse('https://images-api.nasa.gov/search?q=3d%20model&media_type=image')
      ).timeout(const Duration(seconds: 8));

      if (nasaSearchResponse.statusCode == 200) {
        final searchData = json.decode(nasaSearchResponse.body);
        final items = searchData['collection']['items'] as List;

        List<Future<Map<String, dynamic>?>> fetchTasks = items.take(10).map((item) async {
          final meta = item['data'][0];
          final nasaId = meta['nasa_id'];

          try {
            final assetRes = await http.get(Uri.parse('https://images-api.nasa.gov/asset/$nasaId'));
            if (assetRes.statusCode == 200) {
              final List files = json.decode(assetRes.body)['collection']['items'];
              // Look for GLB (Android/Web/Windows) and USDZ (iOS)
              var glb = files.firstWhere(
                      (f) => f['href'].toString().toLowerCase().endsWith('.glb'),
                  orElse: () => null
              );
              var usdz = files.firstWhere(
                      (f) => f['href'].toString().toLowerCase().endsWith('.usdz'),
                  orElse: () => null
              );

              if (glb != null) {
                return {
                  "id": nasaId,
                  "title": meta['title'],
                  "description": "Official NASA Space Asset",
                  "model_android": glb['href'],
                  "model_ios": usdz != null ? usdz['href'] : glb['href'],
                };
              }
            }
          } catch (_) {}
          return null;
        }).toList();

        final results = await Future.wait(fetchTasks);
        final List nasaLessons = results.whereType<Map<String, dynamic>>().toList();

        if (mounted && nasaLessons.isNotEmpty) {
          setState(() {
            allSubjects.add({
              "id": "nasa_lab",
              "name": "NASA Space Lab",
              "icon": "🚀",
              "lessons": nasaLessons
            });
            filteredSubjects = allSubjects;
            loading = false;
          });
        } else {
          if (mounted) setState(() => loading = false);
        }
      }
    } catch (e) {
      debugPrint("NASA fetch failed: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  void _onSearchChanged() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredSubjects = allSubjects.where((subject) {
        bool subjectMatch = subject['name'].toString().toLowerCase().contains(query);
        bool lessonMatch = (subject['lessons'] as List).any((lesson) =>
            lesson['title'].toString().toLowerCase().contains(query));
        return subjectMatch || lessonMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFFF0F9FF),
            flexibleSpace: FlexibleSpaceBar(
              background: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('Magic Learning 🌈', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 32, color: Color(0xFF2C3E50))),
                  const Text('Classroom & NASA Space Lab', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueAccent)),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search for models...',
                          hintStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                          prefixIcon: Icon(Icons.search_rounded, color: Colors.orange, size: 30),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          loading
              ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Colors.orange)))
              : SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, i) {
                  final subject = filteredSubjects[i];
                  final String displayIcon = (subject['icon'] == null || subject['icon'].isEmpty) ? "📖" : subject['icon'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: ExpansionTile(
                        collapsedIconColor: Colors.orange,
                        iconColor: Colors.orange,
                        tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFFFFF4E5), borderRadius: BorderRadius.circular(20)),
                          child: Text(displayIcon, style: const TextStyle(fontSize: 32)),
                        ),
                        title: Text(subject['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF2C3E50))),
                        children: (subject['lessons'] as List).map<Widget>((lesson) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ARViewerScreen(
                                      title: lesson['title'],
                                      glb: lesson['model_android'],
                                      usdz: lesson['model_ios'],
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F9FC),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Row(
                                  children: [
                                    const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.play_arrow_rounded, color: Colors.orange)),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(lesson['title'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                                          Text(lesson['description'] ?? 'Tap to explore!', style: const TextStyle(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right_rounded, color: Colors.black26),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
                childCount: filteredSubjects.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ARViewerScreen extends StatefulWidget {
  final String title;
  final String glb;
  final String usdz;

  const ARViewerScreen({super.key, required this.title, required this.glb, required this.usdz});

  @override
  State<ARViewerScreen> createState() => _ARViewerScreenState();
}

class _ARViewerScreenState extends State<ARViewerScreen> {
  // macOS Controller
  WebViewController? _macOSController;

  // Windows Controller
  // We use the alias 'win' to access the Windows WebView specific classes
  final win.WebviewController _windowsController = win.WebviewController();
  bool _windowsInitialized = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    // Platform-specific initialization
    if (!kIsWeb && Platform.isMacOS) {
      _initMacOS();
    } else if (!kIsWeb && Platform.isWindows) {
      _initWindows();
    }
  }

  @override
  void dispose() {
    // Only dispose windows controller if we are actually on Windows
    if (!kIsWeb && Platform.isWindows) {
      _windowsController.dispose();
    }
    super.dispose();
  }

  void _initMacOS() {
    _macOSController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadHtmlString(_modelViewerHtml(widget.glb));
  }

  Future<void> _initWindows() async {
    try {
      await _windowsController.initialize();

      // Listen for when the webview is ready
      _windowsController.url.listen((url) {
        // You can handle URL changes here if needed
      });

      if (!mounted) return;

      setState(() {
        _windowsInitialized = true;
      });

      // Load the HTML content
      await _windowsController.loadStringContent(_modelViewerHtml(widget.glb));
    } catch (e) {
      debugPrint("Windows WebView init error: $e");
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _openAR() async {
    if (kIsWeb) {
      _showARNotSupportedPopup();
      return;
    }
    if (Platform.isIOS) {
      await launchUrl(Uri.parse(widget.usdz), mode: LaunchMode.externalApplication);
      return;
    }
    if (Platform.isAndroid) {
      final uri = Uri.parse('intent://arvr.google.com/scene-viewer/1.0?file=${widget.glb}&mode=ar_only#Intent;scheme=https;package=com.google.ar.core;end;');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showARNotSupportedPopup();
      }
    }
  }

  void _showARNotSupportedPopup() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
        title: const Text('Hello! 👋', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("You can explore the 3D model right here on your screen!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cool!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (!kIsWeb && Platform.isWindows) {
      if (_errorMessage.isNotEmpty) {
        content = Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SelectableText(
                  "System Error: $_errorMessage\n\nEnsure 'webview_windows' is configured in windows/runner/main.cpp",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
              ),
            )
        );
      } else {
        content = _windowsInitialized
            ? win.Webview(_windowsController)
            : const Center(child: CircularProgressIndicator(color: Colors.orange));
      }
    } else if (!kIsWeb && Platform.isMacOS && _macOSController != null) {
      content = WebViewWidget(controller: _macOSController!);
    } else {
      // Android, iOS, Web fallback to ModelViewer
      content = ModelViewer(
        src: widget.glb,
        autoRotate: true,
        cameraControls: true,
        ar: false, // AR handled by the button
        loading: Loading.eager,
        backgroundColor: Colors.white,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2C3E50))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: const Text("🖱️ Click or Touch to spin!", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.blueGrey)),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(45),
                border: Border.all(color: Colors.white, width: 10),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 15))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: content,
              ),
            ),
          ),
          // Show Magic AR button only on Mobile
          if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 0, 30, 40),
              child: SizedBox(
                width: double.infinity,
                height: 80,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.auto_awesome_rounded, size: 30),
                  label: const Text('MAGIC AR VIEW', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    elevation: 10,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: _openAR,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // HTML content for Windows/MacOS WebViews
  String _modelViewerHtml(String url) {
    return '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<script type="module" src="https://ajax.googleapis.com/ajax/libs/model-viewer/3.3.0/model-viewer.min.js"></script>
<style>
  html, body { margin: 0; padding: 0; background: #ffffff; width: 100%; height: 100%; overflow: hidden; }
  model-viewer { width: 100%; height: 100%; }
</style>
</head>
<body>
<model-viewer 
  src="$url" 
  camera-controls 
  auto-rotate 
  shadow-intensity="1" 
  disable-zoom>
</model-viewer>
</body>
</html>
''';
  }
}