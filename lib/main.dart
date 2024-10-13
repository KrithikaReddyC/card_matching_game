// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'dart:async';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: ChangeNotifierProvider(
//         create: (_) => GameState(),
//         child: GameScreen(),
//       ),
//     );
//   }
// }

// // Card Model
// class CardModel {
//   final String id;
//   final String frontDesign;
//   final String backDesign;
//   bool isFaceUp;
//   bool isMatched;

//   CardModel({
//     required this.id,
//     required this.frontDesign,
//     this.backDesign = "assets/card_back.png", // Replace with your asset
//     this.isFaceUp = false,
//     this.isMatched = false,
//   });
// }

// // Game State
// class GameState extends ChangeNotifier {
//   List<CardModel> cards = [];
//   int score = 0;
//   bool isGameWon = false;
//   Timer? _timer;
//   int elapsedTime = 0;

//   GameState() {
//     _initializeCards();
//     _startTimer();
//   }

//   void _initializeCards() {
//     // Initialize cards with pairs and shuffle them
//     cards = List.generate(8, (index) {
//       final id = index.toString();
//       return [
//         CardModel(id: id, frontDesign: 'assets/A-spade.jpg'),
//         CardModel(id: id, frontDesign: 'assets/Q-heart.jpg')
//       ];
//     }).expand((pair) => pair).toList()
//       ..shuffle();

//     notifyListeners();
//   }

//   void _startTimer() {
//     _timer?.cancel();
//     elapsedTime = 0;
//     _timer = Timer.periodic(const Duration(seconds: 1), (_) {
//       elapsedTime++;
//       notifyListeners();
//     });
//   }

//   void flipCard(CardModel card) {
//     if (!card.isMatched && !card.isFaceUp) {
//       card.isFaceUp = true;
//       notifyListeners();
//       _checkForMatch();
//     }
//   }

//   void _checkForMatch() {
//     final faceUpCards = cards.where((card) => card.isFaceUp && !card.isMatched).toList();
//     if (faceUpCards.length == 2) {
//       if (faceUpCards[0].id == faceUpCards[1].id) {
//         faceUpCards[0].isMatched = true;
//         faceUpCards[1].isMatched = true;
//         score += 10;  // Increment score for each match
//         notifyListeners();
//       } else {
//         Future.delayed(const Duration(seconds: 1), () {
//           faceUpCards[0].isFaceUp = false;
//           faceUpCards[1].isFaceUp = false;
//           notifyListeners();
//         });
//       }
//     }

//     if (cards.every((card) => card.isMatched)) {
//       isGameWon = true;
//       _timer?.cancel();
//       notifyListeners();
//     }
//   }

//   void resetGame() {
//     score = 0;
//     isGameWon = false;
//     _initializeCards();
//     _startTimer();
//   }
// }

// // Game Screen UI
// class GameScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final gameState = Provider.of<GameState>(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Card Matching Game'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.restart_alt),
//             onPressed: gameState.resetGame,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: [
//               Text('Score: ${gameState.score}'),
//               Text('Time: ${gameState.elapsedTime}s'),
//             ],
//           ),
//           Expanded(
//             child: GridView.builder(
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 4,
//               ),
//               itemCount: gameState.cards.length,
//               itemBuilder: (context, index) {
//                 final card = gameState.cards[index];
//                 return GestureDetector(
//                   onTap: () => gameState.flipCard(card),
//                   child: CardWidget(card: card),
//                 );
//               },
//             ),
//           ),
//           if (gameState.isGameWon)
//             const Padding(
//               padding: EdgeInsets.all(16.0),
//               child: Text(
//                 'Congratulations! You won!',
//                 style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

// // Card Widget with Animation
// class CardWidget extends StatelessWidget {
//   final CardModel card;

//   CardWidget({required this.card});

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 500),
//       decoration: BoxDecoration(
//         image: DecorationImage(
//           image: AssetImage(card.isFaceUp ? card.frontDesign : card.backDesign),
//           fit: BoxFit.cover,
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => GameProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Matching Cards',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CardGridScreen(),
    );
  }
}

class CardModel {
  final String frontImage;
  final String backImage;
  bool isFaceUp;

  CardModel({
    required this.frontImage,
    required this.backImage,
    this.isFaceUp = false,
  });
}

class GameProvider with ChangeNotifier {
  List<CardModel> _cards = [];
  List<CardModel> _flippedCards = [];
  int _score = 0;
  int _matchedPairs = 0;
  bool _isGameOver = false;
  Timer? _timer;
  int _timeElapsed = 0;
  int _bestScore = 0;
  int _bestTime = 0;

  GameProvider() {
    _initializeCards();
    _loadBestScore();
    _loadBestTime();
    _startTimer();
  }

  List<CardModel> get cards => _cards;
  int get score => _score;
  int get timeElapsed => _timeElapsed;
  bool get isGameOver => _isGameOver;
  int get bestScore => _bestScore;
  int get bestTime => _bestTime;

  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    _bestScore = prefs.getInt('bestScore') ?? 0;
    notifyListeners();
  }

  Future<void> _loadBestTime() async {
    final prefs = await SharedPreferences.getInstance();
    _bestTime = prefs.getInt('bestTime') ?? 0;
    notifyListeners();
  }

  Future<void> _saveBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    if (_score > _bestScore) {
      _bestScore = _score;
      await prefs.setInt('bestScore', _bestScore);
    }
  }

  Future<void> _saveBestTime() async {
    final prefs = await SharedPreferences.getInstance();
    if (_timeElapsed < _bestTime || _bestTime == 0) {
      _bestTime = _timeElapsed;
      await prefs.setInt('bestTime', _bestTime);
    }
  }

  void _initializeCards() {
    _cards = [
      CardModel(
          frontImage: 'assets/2spade.jpeg', backImage: 'assets/backcard.jpeg'),
      CardModel(
          frontImage: 'assets/2spade.jpeg', backImage: 'assets/backcard.jpeg'),
      CardModel(
          frontImage: 'assets/3spade.jpeg', backImage: 'assets/backcard.jpeg'),
      CardModel(
          frontImage: 'assets/3spade.jpeg', backImage: 'assets/backcard.jpeg'),
      CardModel(
          frontImage: 'assets/4spade.png', backImage: 'assets/backcard.jpeg'),
      CardModel(
          frontImage: 'assets/4spade.png', backImage: 'assets/backcard.jpeg'),
      CardModel(
          frontImage: 'assets/5spade.jpeg', backImage: 'assets/backcard.jpeg'),
      CardModel(
          frontImage: 'assets/5spade.jpeg', backImage: 'assets/backcard.jpeg'),
      CardModel(
          frontImage: 'assets/6spade.jpeg', backImage: 'assets/backcard.jpeg'),
      CardModel(
          frontImage: 'assets/6spade.jpeg', backImage: 'assets/backcard.jpeg'),
      CardModel(
          frontImage: 'assets/7spade.jpeg', backImage: 'assets/backcard.jpeg'),
      CardModel(
          frontImage: 'assets/7spade.jpeg', backImage: 'assets/backcard.jpeg'),
       CardModel(
          frontImage: 'assets/8spade.jpeg', backImage: 'assets/backcard.jpeg'),
      CardModel(
          frontImage: 'assets/8spade.jpeg', backImage: 'assets/backcard.jpeg'),
      CardModel(
          frontImage: 'assets/9spade.png', backImage: 'assets/backcard.jpeg'),
      CardModel(
          frontImage: 'assets/9spade.png', backImage: 'assets/backcard.jpeg'),
    ];

    _cards.shuffle();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _timeElapsed++;
      notifyListeners();
    });
  }

  void flipCard(int index, BuildContext context) {
    if (_cards[index].isFaceUp || _flippedCards.length >= 2 || _isGameOver)
      return;

    _cards[index].isFaceUp = true;
    _flippedCards.add(_cards[index]);

    notifyListeners();

    if (_flippedCards.length == 2) {
      Future.delayed(Duration(seconds: 1), () {
        if (_flippedCards[0].frontImage == _flippedCards[1].frontImage) {
          _score += 10; // Score for matching
          _matchedPairs++;
          if (_matchedPairs == _cards.length ~/ 2) {
            _isGameOver = true;
            _timer?.cancel(); // Stop the timer
            _saveBestScore(); // Save best score if needed
            _saveBestTime(); // Save best time if needed
            _showVictoryDialog(context); // Pass context to show dialog
          }
        } else {
          _score -= 5; // Penalty for mismatching
          _flippedCards[0].isFaceUp = false;
          _flippedCards[1].isFaceUp = false;
        }
        _flippedCards.clear();
        notifyListeners();
      });
    }
  }

  void _showVictoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Congratulations!'),
          content: Text(
              'You matched all pairs!\nScore: $_score\nBest Score: $_bestScore\nTime: $_timeElapsed seconds\nBest Time: $_bestTime seconds'),
          actions: [
            TextButton(
              child: Text('Restart Game'),
              onPressed: () {
                resetGame();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void resetGame() {
    _initializeCards();
    _score = 0;
    _matchedPairs = 0;
    _isGameOver = false;
    _timeElapsed = 0;
    _timer?.cancel();
    _startTimer();
    notifyListeners();
  }
}

class CardGridScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Card Flip Game'),
      ),
      body: Center(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Score: ${gameProvider.score}',
                      style: TextStyle(fontSize: 20)),
                  Text('Best Score: ${gameProvider.bestScore}',
                      style: TextStyle(fontSize: 20)),
                  Text('Time: ${gameProvider.timeElapsed}s',
                      style: TextStyle(fontSize: 20)),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.all(8.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.75,
                ),
                itemCount: gameProvider.cards.length,
                itemBuilder: (context, index) {
                  final card = gameProvider.cards[index];

                  return GestureDetector(
                    onTap: () => gameProvider.flipCard(index, context),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      margin: EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(
                              card.isFaceUp ? card.frontImage : card.backImage),
                          fit: BoxFit.cover,
                        ),
                      ),
                      height: 100,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: card.isFaceUp
                            ? Matrix4.identity()
                            : Matrix4.rotationY(3.14),
                        child: Container(),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (gameProvider.isGameOver)
              ElevatedButton(
                onPressed: () {
                  gameProvider.resetGame();
                },
                child: Text('Restart Game'),
              ),
          ],
        ),
      ),
    );
  }
}