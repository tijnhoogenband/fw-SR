import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:open_route_service/open_route_service.dart';
import 'map_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'De Slimste Mens - Puzzelronde',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromARGB(255, 92, 92, 92), // A lighter dark grey
        cardColor: const Color.fromARGB(255, 129, 129, 129), // A step lighter for cards
        textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: TextStyle(color: Colors.grey.shade300),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: const Color(0xFF757575), // Another step lighter for inputs
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey, // Grey seed color
          brightness: Brightness.dark,
        ).copyWith(secondary: Colors.grey.shade400),
      ),
      home: const MainScreen(),
    );
  }
}

// Data structure for the puzzle
class Puzzle {
  final Map<String, List<String>> connections;
  final List<String> gridWords;
  final Map<String, String> wordToConnection;

  // Private constructor that just assigns final fields
  Puzzle._({
    required this.connections,
    required this.gridWords,
    required this.wordToConnection,
  });

  // Public factory constructor to handle the logic
  factory Puzzle({required Map<String, List<String>> connections}) {
    final gridWords =
        connections.values.expand((words) => words).toList()..shuffle();
    final wordToConnection = <String, String>{};
    connections.forEach((connection, words) {
      for (var word in words) {
        wordToConnection[word] = connection;
      }
    });
    // Return a new instance using the private constructor
    return Puzzle._(
      connections: connections,
      gridWords: gridWords,
      wordToConnection: wordToConnection,
    );
  }
}

// Game data
final puzzleData = Puzzle(
  connections: {
    'Bleken': ['Tanden', 'Witten', 'Vaal worden', 'Chloor'],
    'Drie': ['Biggetjes', 'K', 'Musketiers', 'Hoek'],
    'Nederland': ['Oranje', 'Fiets', 'Leeuw', 'Polder'],
    'Wezel': ['Marter', 'Kastanjebruin', 'Muishond', 'Burgemeester'],
    'Belgie': ['Kasseien', 'Lars', 'Spa', 'Moppen'],
    'Acht': ['Oneindig', 'Spin', 'Octaaf', 'Byte'],
    'Friesland': ['Doorloper', 'Zeilen', 'Kaatsen', 'Meren'],
    'Dam': ['Bever', 'Hydro', 'Steen', 'Blokkade'],
    'Bergen': ['Heuvels', 'Verzetten', 'Noorwegen', 'Alpen'],
    'El': ['Eetlepel', 'Nino', 'Lengtemaat', 'Boog'],
    'Een': ['Mono', 'Top', 'Winnaar', 'Solo'],
    'Zeeland': ['Eilanden', 'Storm', 'Mosselen', 'Bolus'],
    'Dal': ['Uren', 'Ton', 'Vallei', 'Inhoudsmaat'],
    'Duitsland': ['Auto', 'Oorlog', 'Beethoven', 'Kerstmarkt'],
    'Vijf': ['Olympische ringen', 'Jackson', 'Pentagon', 'Zintuigen'],
    // 'Hout': ['Brand', 'Papier', 'Meubels', 'Snijden'],
  },
);

final puzzle1Data = Puzzle(
    connections: Map.fromEntries(puzzleData.connections.entries.take(4)));
final puzzle2Data = Puzzle(
    connections:
        Map.fromEntries(puzzleData.connections.entries.skip(4).take(4)));

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _isPuzzle2Locked = true;

  void _unlockPuzzle2() {
    setState(() {
      _isPuzzle2Locked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: PuzzleGame(
                puzzleData: puzzle1Data,
                onCompleted: _unlockPuzzle2,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _isPuzzle2Locked
                  ? const LockedPuzzle()
                  : PuzzleGame(
                      puzzleData: puzzle2Data,
                      onCompleted: () {
                        // Optional: Add logic for when the second puzzle is completed
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class LockedPuzzle extends StatelessWidget {
  const LockedPuzzle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(
          Icons.lock_outline,
          size: 80,
          color: Colors.white54,
        ),
      ),
    );
  }
}

class PuzzleGame extends StatefulWidget {
  final Puzzle puzzleData;
  final VoidCallback onCompleted;

  const PuzzleGame({
    super.key,
    required this.puzzleData,
    required this.onCompleted,
  });

  @override
  _PuzzleGameState createState() => _PuzzleGameState();
}

class _PuzzleGameState extends State<PuzzleGame> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<String> _foundConnections = [];
  final Set<String> _foundWords = {};
  bool _showIncorrectAnimation = false;
  String _incorrectAnswerText = '';
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _checkAnswer() {
    if (_showIncorrectAnimation || _isCompleted) return;

    final text = _controller.text;
    final upperCaseText = text.toUpperCase();

    // Find the correct key in a case-insensitive way
    String? correctKey;
    for (var key in widget.puzzleData.connections.keys) {
      if (key.toUpperCase() == upperCaseText) {
        correctKey = key;
        break;
      }
    }

    if (correctKey != null &&
        !_foundConnections.contains(correctKey)) {
      setState(() {
        _foundConnections.add(correctKey!);
        _foundWords.addAll(widget.puzzleData.connections[correctKey]!);
        _controller.clear();
      });
      _focusNode.requestFocus();

      if (_foundConnections.length == 4) {
        setState(() {
          _isCompleted = true;
        });
        widget.onCompleted();
      }
    } else {
      if (_controller.text.isEmpty) {
        _focusNode.requestFocus();
        return;
      }

      setState(() {
        _incorrectAnswerText = _controller.text;
        _showIncorrectAnimation = true;
      });
      Timer(const Duration(milliseconds: 500), () {
        setState(() {
          _controller.clear();
          _showIncorrectAnimation = false;
          _incorrectAnswerText = '';
        });
        _focusNode.requestFocus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Top boxes for found connections
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(4, (index) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Center(
                  child: Text(
                    index < _foundConnections.length
                        ? _foundConnections[index]
                        : '',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        // 4x4 Grid in a rounded box
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: LayoutBuilder(builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 3 * 10) / 4;
              final itemHeight = (constraints.maxHeight - 3 * 10) / 4;
              final aspectRatio = itemHeight > 0 ? itemWidth / itemHeight : 1.0;

              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: aspectRatio,
                ),
                itemCount: 16,
                itemBuilder: (context, index) {
                  final word = widget.puzzleData.gridWords[index];
                  final isFound = _foundWords.contains(word);
                  final connection =
                      isFound ? widget.puzzleData.wordToConnection[word] : null;

                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isFound
                            ? Colors.green.shade700.withOpacity(0.7)
                            : Colors.grey.withOpacity(0.2),
                        width: isFound ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: isFound
                          ? Colors.green.withOpacity(0.2)
                          : Theme.of(context).cardColor,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (connection != null)
                            Text(
                              connection,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withOpacity(0.7),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          Text(
                            word,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ),
        const SizedBox(height: 20),
        // Input bar and button
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onSubmitted: (_) => _checkAnswer(),
                decoration: InputDecoration(
                  hintText: 'Typ hier je antwoord',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: _showIncorrectAnimation
                            ? Colors.red.withOpacity(0.7)
                            : Colors.transparent,
                        width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: _showIncorrectAnimation
                            ? Colors.red.withOpacity(0.7)
                            : Theme.of(context).colorScheme.secondary,
                        width: 1.5),
                  ),
                ),
                style: TextStyle(
                    color: _showIncorrectAnimation
                        ? Colors.red
                        : Colors.white),
                readOnly: _showIncorrectAnimation || _isCompleted,
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: _isCompleted ? null : _checkAnswer,
              style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side:
                        BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                  padding: const EdgeInsets.all(16)),
            ),
          ],
        ),
      ],
    );
  }
}
