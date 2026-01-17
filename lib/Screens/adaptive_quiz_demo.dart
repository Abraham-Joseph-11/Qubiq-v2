// lib/Screens/adaptive_learning_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ For Storing Levels
import 'dart:ui';

// ✅ Import your WebView screen
import 'package:little_emmi/Screens/inappwebview_screen.dart';

// ==========================================
// 1. DATABASE & CONFIGURATION
// ==========================================

class Question {
  final String id;
  final int level;
  final String text;
  final List<String> options;
  final String answer; // The correct VALUE (e.g. "8")

  Question({
    required this.id,
    required this.level,
    required this.text,
    required this.options,
    required this.answer,
  });
}

// 📚 SUBJECT DATABASE
// Maps Subject Name -> List of Questions
final Map<String, List<Question>> subjectData = {
  "Maths": [
    // Level 1: Basics
    Question(id: "m1", level: 1, text: "5 + 3 = ?", options: ["A) 7", "B) 8", "C) 9", "D) 10"], answer: "8"),
    Question(id: "m2", level: 1, text: "10 - 4 = ?", options: ["A) 5", "B) 6", "C) 7", "D) 4"], answer: "6"),
    // Level 2: Intermediate
    Question(id: "m3", level: 2, text: "12 x 5 = ?", options: ["A) 50", "B) 60", "C) 55", "D) 65"], answer: "60"),
    Question(id: "m4", level: 2, text: "48 / 6 = ?", options: ["A) 6", "B) 7", "C) 8", "D) 9"], answer: "8"),
    // Level 3: Advanced
    Question(id: "m5", level: 3, text: "15 x 15 = ?", options: ["A) 200", "B) 225", "C) 250", "D) 215"], answer: "225"),
  ],
  "Python": [
    // Level 1: Basics
    Question(id: "p1", level: 1, text: "Output of: print('Hello')", options: ["A) Hello", "B) 'Hello'", "C) Error", "D) print"], answer: "Hello"),
    Question(id: "p2", level: 1, text: "Symbol for comments?", options: ["A) //", "B) /*", "C) #", "D) --"], answer: "#"),
    // Level 2: Intermediate
    Question(id: "p3", level: 2, text: "Keyword to define function?", options: ["A) func", "B) def", "C) function", "D) void"], answer: "def"),
    // Level 3: Advanced
    Question(id: "p4", level: 3, text: "Mutable data type?", options: ["A) Tuple", "B) String", "C) List", "D) Int"], answer: "List"),
  ],
  "Science": [
    // Level 1
    Question(id: "s1", level: 1, text: "Center of Solar System?", options: ["A) Earth", "B) Mars", "C) Sun", "D) Moon"], answer: "Sun"),
    // Level 2
    Question(id: "s2", level: 2, text: "Chemical symbol for Water?", options: ["A) HO", "B) H2O", "C) O2", "D) H2"], answer: "H2O"),
    // Level 3
    Question(id: "s3", level: 3, text: "Powerhouse of the cell?", options: ["A) Nucleus", "B) Ribosome", "C) Mitochondria", "D) DNA"], answer: "Mitochondria"),
  ],
  "English": [
    // Level 1
    Question(id: "e1", level: 1, text: "Opposite of 'Happy'?", options: ["A) Joy", "B) Sad", "C) Glad", "D) Mad"], answer: "Sad"),
    // Level 2
    Question(id: "e2", level: 2, text: "Past tense of 'Go'?", options: ["A) Gone", "B) Went", "C) Goed", "D) Going"], answer: "Went"),
    // Level 3
    Question(id: "e3", level: 3, text: "Synonym for 'Benevolent'?", options: ["A) Kind", "B) Cruel", "C) Poor", "D) Rich"], answer: "Kind"),
  ],
  "Social Science": [
    // Level 1
    Question(id: "ss1", level: 1, text: "Shape of Earth?", options: ["A) Flat", "B) Spherical", "C) Square", "D) Oval"], answer: "Spherical"),
    // Level 2
    Question(id: "ss2", level: 2, text: "Capital of India?", options: ["A) Mumbai", "B) Kolkata", "C) New Delhi", "D) Chennai"], answer: "New Delhi"),
    // Level 3
    Question(id: "ss3", level: 3, text: "Who wrote the Constitution?", options: ["A) Gandhi", "B) Ambedkar", "C) Nehru", "D) Patel"], answer: "Ambedkar"),
  ],
};

// 📺 REMEDIAL VIDEOS (Specific per Subject)
final Map<String, String> subjectRemedialVideos = {
  "Maths": "https://www.youtube.com/watch?v=mjLSylzjkHg", // Basic Math
  "Python": "https://www.youtube.com/watch?v=kqtD5dpn9C8", // Python for Beginners
  "Science": "https://www.youtube.com/watch?v=iMJ-pr6tUQA", // General Science
  "English": "https://www.youtube.com/watch?v=JuM8bN3KHgU", // Basic English
  "Social Science": "https://www.youtube.com/watch?v=e_k9Wb9g2hE", // Social Studies
};

// ==========================================
// 2. SCREEN 1: SUBJECT MENU (UPDATED)
// ==========================================

class AdaptiveLearningMenu extends StatelessWidget {
  const AdaptiveLearningMenu({super.key});

  @override
  Widget build(BuildContext context) {
    // Check screen width to determine column count
    double screenWidth = MediaQuery.of(context).size.width;

    // ✅ RESPONSIVE LOGIC:
    // Mobile (<700px): 2 Columns
    // Tablet (700px - 1100px): 3 Columns
    // Desktop (>1100px): 5 Columns (Makes blocks smaller)
    int crossAxisCount = screenWidth > 1100 ? 5 : (screenWidth > 700 ? 3 : 2);

    // Adjust aspect ratio to keep them nice and square-ish
    double childAspectRatio = screenWidth > 1100 ? 1.0 : 1.1;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Select Subject", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)], // Purple Gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0), // Increased padding for cleaner look
            child: GridView.count(
              crossAxisCount: crossAxisCount, // ✅ Dynamic columns
              crossAxisSpacing: 20, // ✅ Increased spacing
              mainAxisSpacing: 20,
              childAspectRatio: childAspectRatio, // ✅ prevents them from being too tall
              children: [
                _buildSubjectCard(context, "Maths", Icons.calculate, Colors.orange),
                _buildSubjectCard(context, "Python", Icons.code, Colors.blue),
                _buildSubjectCard(context, "Science", Icons.science, Colors.green),
                _buildSubjectCard(context, "English", Icons.menu_book, Colors.pink),
                _buildSubjectCard(context, "Social Science", Icons.public, Colors.teal),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext context, String subject, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdaptiveQuizScreen(subject: subject),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(24), // Smoother corners
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(18), // Slightly reduced icon padding
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 12)]
                  ),
                  child: Icon(icon, size: 36, color: color), // Reduced icon size slightly
                ),
                const SizedBox(height: 16),
                Text(
                  subject,
                  style: GoogleFonts.poppins(
                      fontSize: 16, // Reduced font slightly for better fit
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black26, blurRadius: 4)]
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack).fadeIn(duration: 400.ms);
  }
}

// ==========================================
// 3. SCREEN 2: THE ADAPTIVE QUIZ
// ==========================================

class AdaptiveQuizScreen extends StatefulWidget {
  final String subject;
  const AdaptiveQuizScreen({super.key, required this.subject});

  @override
  State<AdaptiveQuizScreen> createState() => _AdaptiveQuizScreenState();
}

class _AdaptiveQuizScreenState extends State<AdaptiveQuizScreen> {
  // State
  Question? _currentQuestion;
  int _currentLevel = 1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserLevel();
  }

  // 💾 1. LOAD SAVED LEVEL
  Future<void> _loadUserLevel() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      // Key format: 'level_Maths', 'level_Python'
      _currentLevel = prefs.getInt('level_${widget.subject}') ?? 1;
      _loadNextQuestion();
    });
  }

  // 💾 2. SAVE LEVEL
  Future<void> _saveUserLevel(int newLevel) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('level_${widget.subject}', newLevel);
  }

  // 🧠 3. GET QUESTION LOGIC
  void _loadNextQuestion() {
    setState(() => _isLoading = true);

    // Simulate "Thinking" delay
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        List<Question> allQuestions = subjectData[widget.subject] ?? [];

        // Find question for current level
        try {
          // Get a random question from the current level to keep it fresh
          List<Question> levelQuestions = allQuestions.where((q) => q.level == _currentLevel).toList();

          if (levelQuestions.isNotEmpty) {
            levelQuestions.shuffle(); // Randomize
            setState(() {
              _currentQuestion = levelQuestions.first;
              _isLoading = false;
            });
          } else {
            // No questions found for this level (User beat the game?)
            setState(() {
              _currentQuestion = null; // Shows Completion Screen
              _isLoading = false;
            });
          }
        } catch (e) {
          setState(() => _isLoading = false);
        }
      }
    });
  }

  // ✅ 4. ANSWER PROCESSING
  void _submitAnswer(String option) {
    // Clean input: "A) 8" -> "8"
    String cleanUser = option.contains(")") ? option.split(")")[1].trim() : option.trim();
    String cleanCorrect = _currentQuestion!.answer.trim();

    bool isCorrect = cleanUser == cleanCorrect;

    if (isCorrect) {
      // LEVEL UP LOGIC
      if (_currentLevel < 3) {
        _currentLevel++;
        _saveUserLevel(_currentLevel); // Save progress
        _showFeedbackDialog(
            isCorrect: true,
            title: "Excellent!",
            msg: "You mastered Level ${_currentLevel - 1}. Moving to Level $_currentLevel!",
            action: "Next Level"
        );
      } else {
        _showFeedbackDialog(
            isCorrect: true,
            title: "Mastery!",
            msg: "You are a ${widget.subject} Expert!",
            action: "Finish"
        );
      }
    } else {
      // FAILURE LOGIC
      if (_currentQuestion!.level == 1) {
        // Failed Basics -> Show Video
        _showRemedialDialog();
      } else {
        // Failed Higher Level -> Downgrade
        _currentLevel--;
        _saveUserLevel(_currentLevel); // Save downgrade
        _showFeedbackDialog(
            isCorrect: false,
            title: "Too Hard?",
            msg: "Let's go back to Level $_currentLevel and strengthen your basics.",
            action: "Try Easier Level"
        );
      }
    }
  }

  void _showRemedialDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildGlassDialog(
        icon: Icons.smart_display_rounded,
        iconColor: Colors.orange,
        title: "Help Needed!",
        message: "It looks like you're stuck on the basics of ${widget.subject}. Let's watch a quick lesson.",
        mainButtonText: "Watch Video",
        onMainPressed: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InAppWebViewScreen(
                url: subjectRemedialVideos[widget.subject] ?? "https://youtube.com",
                title: "Learn ${widget.subject}",
              ),
            ),
          );
        },
        secondaryButtonText: "Skip & Retry",
        onSecondaryPressed: () {
          Navigator.pop(context);
          // Just reload same level
        },
      ),
    );
  }

  void _showFeedbackDialog({required bool isCorrect, required String title, required String msg, required String action}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildGlassDialog(
        icon: isCorrect ? Icons.check_circle : Icons.error_outline,
        iconColor: isCorrect ? Colors.green : Colors.red,
        title: title,
        message: msg,
        mainButtonText: action,
        onMainPressed: () {
          Navigator.pop(context);
          _loadNextQuestion();
        },
      ),
    );
  }

  // --- UI WIDGETS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _currentQuestion == null
              ? _buildCompletionScreen()
              : Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTopicBadge(),
                      const SizedBox(height: 24),
                      _buildQuestionCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  "${widget.subject.toUpperCase()} PATH",
                  style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                // Level Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    bool active = (index + 1) <= _currentLevel;
                    return AnimatedContainer(
                      duration: 300.ms,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active ? Colors.tealAccent : Colors.white12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTopicBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.teal),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.trending_up, color: Colors.tealAccent, size: 18),
          const SizedBox(width: 8),
          Text(
            "CURRENT LEVEL: $_currentLevel",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.5);
  }

  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white24),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.subject,
            style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2.0),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            _currentQuestion!.text,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ..._currentQuestion!.options.map((opt) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildOptionButton(opt),
          )),
        ],
      ),
    ).animate().slideY(begin: 0.1, duration: 400.ms);
  }

  Widget _buildOptionButton(String text) {
    List<String> parts = text.split(')');
    String prefix = parts[0];
    String value = parts.length > 1 ? parts[1].trim() : "";

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.blueGrey[900],
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      onPressed: () => _submitAnswer(text),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), shape: BoxShape.circle),
            child: Text(prefix, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.indigo)),
          ),
          const SizedBox(width: 16),
          Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildGlassDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String mainButtonText,
    required VoidCallback onMainPressed,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
  }) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.white.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 48),
              ).animate().scale(curve: Curves.elasticOut),
              const SizedBox(height: 20),
              Text(title, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueGrey[900])),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 15, color: Colors.blueGrey[600], height: 1.5)),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 5,
                    shadowColor: iconColor.withOpacity(0.4),
                  ),
                  onPressed: onMainPressed,
                  child: Text(mainButtonText, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                ),
              ),
              if (secondaryButtonText != null) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: onSecondaryPressed,
                  child: Text(secondaryButtonText, style: GoogleFonts.poppins(color: Colors.blueGrey[400], fontWeight: FontWeight.w600)),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionScreen() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 100, color: Colors.amber),
          const SizedBox(height: 20),
          Text("Module Mastered!", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          Text("You have finished all questions for ${widget.subject}.", textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16)),
            onPressed: () => Navigator.pop(context),
            child: Text("Return to Menu", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    ).animate().fadeIn();
  }
}