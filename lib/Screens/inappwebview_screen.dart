// lib/Screens/inappwebview_screen.dart

import 'dart:ui'; // For ImageFilter.blur
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class InAppWebViewScreen extends StatefulWidget {
  final String title;
  final String url;

  const InAppWebViewScreen({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<InAppWebViewScreen> createState() => _InAppWebViewScreenState();
}

class _InAppWebViewScreenState extends State<InAppWebViewScreen> {
  InAppWebViewController? _webViewController;
  double _progress = 0;

  // MIT App Inventor Specific Flags
  bool _hasShownLoginPopup = false;
  bool _showRevisitCodePopup = false;
  final _revisitCodeController = TextEditingController();

  // Helper to check if we are currently running an Office/Microsoft app
  bool get _isOfficeApp => widget.url.contains('microsoft') || widget.url.contains('office') || widget.url.contains('bing');

  // Helper to check if we are using MIT App Inventor
  bool get _isMitApp => widget.url.contains('mit.edu');

  @override
  void dispose() {
    _revisitCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Refresh button is helpful for all apps in case a page gets stuck
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _webViewController?.reload();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),

            // --- ✅ CRITICAL UPDATE FOR PERSISTENT LOGIN ---
            initialSettings: InAppWebViewSettings(
              // 1. Persistence Settings (Keeps user logged in)
              cacheEnabled: true,
              domStorageEnabled: true,
              databaseEnabled: true,
              thirdPartyCookiesEnabled: true, // Required for Google/Microsoft Auth
              sharedCookiesEnabled: true, // iOS specific
              saveFormData: true,

              // 2. User Agent Logic
              // Office needs Desktop UA. Others need a valid Mobile UA to avoid "Browser not supported".
              userAgent: _isOfficeApp
                  ? "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36"
                  : "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36",

              // 3. View Settings
              javaScriptEnabled: true,
              useWideViewPort: true, // Helps with rendering desktop-like sites
              loadWithOverviewMode: true,

              // 4. Media Settings (Important for Suno AI music playback)
              mediaPlaybackRequiresUserGesture: false,
              allowsInlineMediaPlayback: true,
            ),

            onWebViewCreated: (controller) {
              _webViewController = controller;
            },

            // Shows loading bar
            onProgressChanged: (controller, progress) {
              setState(() {
                _progress = progress / 100;
              });
            },

            // ✅ Handles Popups (like "Sign in with Google")
            onCreateWindow: (controller, createWindowAction) async {
              return true; // Allow the popup to open
            },

            onLoadStop: (controller, url) {
              if (url == null) return;
              String currentUrl = url.toString();

              // --- LOGIC ISOLATION ---
              // Only run this logic if we are actually on an MIT site
              if (_isMitApp) {
                _handleMitUrlEvents(currentUrl);
              }
              // For other apps, ensure popups are hidden
              else {
                if (_showRevisitCodePopup) {
                  setState(() {
                    _showRevisitCodePopup = false;
                  });
                }
              }
            },
          ),

          // --- LOADING INDICATOR ---
          if (_progress < 1.0)
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.tealAccent),
            ),

          // --- MIT SPECIFIC OVERLAY ---
          if (_showRevisitCodePopup)
            _buildRevisitCodePopup(context),
        ],
      ),
    );
  }

  // --- Helper to handle MIT specific URL logic ---
  void _handleMitUrlEvents(String currentUrl) {
    // 1. Check for Login Page
    if (currentUrl.startsWith('https://login.appinventor.mit.edu') &&
        !_hasShownLoginPopup) {
      setState(() {
        _hasShownLoginPopup = true;
        _showRevisitCodePopup = false;
      });
      _showLoginPopup(context);
    }
    // 2. Check for Editor Page
    else if (currentUrl.startsWith('https://code2.appinventor.mit.edu')) {
      setState(() {
        _showRevisitCodePopup = true;
      });
    }
    // 3. Any other MIT page
    else {
      setState(() {
        _showRevisitCodePopup = false;
      });
    }
  }

  // --- WIDGETS (MIT Specific) ---

  Widget _buildRevisitCodePopup(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
      left: 20.0,
      right: 20.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter Revisit Code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scroll to find the code.',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _revisitCodeController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Revisit Code',
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                      onPressed: () {
                        _revisitCodeController.clear();
                        FocusScope.of(context).unfocus();
                        setState(() {
                          _showRevisitCodePopup = false;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BFA6),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Submit'),
                      onPressed: () {
                        _revisitCodeController.clear();
                        FocusScope.of(context).unfocus();
                        setState(() {
                          _showRevisitCodePopup = false;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLoginPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('MIT App Inventor Login'),
          content: const Text('Please log in with your Google account to continue.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}