import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class IntroSlotScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const IntroSlotScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<IntroSlotScreen> createState() => _IntroSlotScreenState();
}

class _IntroSlotScreenState extends State<IntroSlotScreen> {
  // Zeichen für die Slot-Machine
  final List<String> chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".split('');
  final Random rnd = Random();
  
  // Animation Control
  Timer? _timer;
  bool _finished = false;
  int _ticks = 0;
  
  // Drei Zeilen Text
  final List<String> targetLines = [
    "Zufallszahlengenerator",
    "für 6aus49 und Eurojackpot", 
    "by Funatiker"
  ];
  
  // Aktuelle Anzeige (jede Zeile als Liste von Zeichen)
  List<List<String>> currentDisplay = [];
  
  @override
  void initState() {
    super.initState();
    
    // Initialisiere Display mit zufälligen Zeichen
    currentDisplay = targetLines.map((line) {
      return List<String>.generate(line.length, (_) => chars[rnd.nextInt(chars.length)]);
    }).toList();
    
    // Starte Animation
    _startSlotAnimation();
  }
  
  void _startSlotAnimation() {
    const frameDuration = Duration(milliseconds: 60);
    
    _timer = Timer.periodic(frameDuration, (timer) {
      if (!mounted) return;
      
      setState(() {
        _ticks++;
        
        // Phase 1: Volles Chaos (0-30 Frames)
        if (_ticks <= 30) {
          for (int lineIdx = 0; lineIdx < targetLines.length; lineIdx++) {
            final lineLength = targetLines[lineIdx].length;
            currentDisplay[lineIdx] = List<String>.generate(
              lineLength,
              (_) => chars[rnd.nextInt(chars.length)]
            );
          }
        }
        // Phase 2: Allmähliches Einrasten (31-80 Frames)
        else if (_ticks <= 80) {
          final progress = (_ticks - 30) / 50; // 0.0 bis 1.0
          
          for (int lineIdx = 0; lineIdx < targetLines.length; lineIdx++) {
            final targetLine = targetLines[lineIdx];
            
            for (int charIdx = 0; charIdx < targetLine.length; charIdx++) {
              // Zufällige Chance basierend auf Fortschritt
              if (rnd.nextDouble() < progress) {
                currentDisplay[lineIdx][charIdx] = targetLine[charIdx];
              } else if (_ticks % 3 == 0) {
                // Immer noch zufällig wechseln
                currentDisplay[lineIdx][charIdx] = chars[rnd.nextInt(chars.length)];
              }
            }
          }
        }
        // Phase 3: Fertig stellen (ab Frame 81)
        else if (!_finished) {
          // Setze finale Texte
          for (int lineIdx = 0; lineIdx < targetLines.length; lineIdx++) {
            final targetLine = targetLines[lineIdx];
            currentDisplay[lineIdx] = targetLine.split('');
          }
          
          _finished = true;
          timer.cancel();
          
          // Nach kurzer Pause weiter zur Haupt-App
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (mounted) {
              widget.onComplete();
            }
          });
        }
      });
    });
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  Widget _buildSlotMachine() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(33, 33, 33, 255),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.yellow,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.yellow.withAlpha(50),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: currentDisplay.asMap().entries.map((entry) {
          final lineIndex = entry.key;
          final lineChars = entry.value;
          
          return Padding(
            padding: EdgeInsets.only(
              bottom: lineIndex < currentDisplay.length - 1 ? 12.0 : 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: lineChars.asMap().entries.map((charEntry) {
                final charIndex = charEntry.key;
                final character = charEntry.value;
                final targetChar = targetLines[lineIndex][charIndex];
                
                // Besondere Hervorhebung für korrekte Zeichen
                final isCorrect = character == targetChar;
                
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 20,
                  height: 38,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: isCorrect 
                        ? const Color.fromRGBO(40, 40, 40, 255)
                        : const Color.fromRGBO(25, 25, 25, 255),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isCorrect 
                          ? Colors.yellow.withAlpha(150)
                          : Colors.grey.shade800,
                      width: isCorrect ? 1.5 : 1,
                    ),
                    boxShadow: isCorrect 
                        ? [
                            BoxShadow(
                              color: Colors.yellow.withAlpha(30),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    character,
                    style: TextStyle(
                      color: isCorrect ? Colors.yellow : Colors.yellow.withAlpha(180),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Monospace',
                      letterSpacing: 0,
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildStatusIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Fortschrittsindikator
        SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            value: _finished ? 1.0 : _ticks / 80.0,
            backgroundColor: Colors.grey.shade800,
            valueColor: AlwaysStoppedAnimation<Color>(
              _finished ? Colors.green : Colors.yellow,
            ),
            borderRadius: BorderRadius.circular(10),
            minHeight: 6,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Status Text
        Text(
          _finished 
              ? "✅ App wird gestartet..."
              : "🎰 Slot-Machine läuft...",
          style: TextStyle(
            color: _finished ? Colors.green : Colors.yellow,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Skip Button (nur während Animation)
        if (!_finished)
          ElevatedButton.icon(
            onPressed: () {
              _timer?.cancel();
              widget.onComplete();
            },
            icon: const Icon(Icons.fast_forward, size: 18),
            label: const Text(
              "Intro überspringen",
              style: TextStyle(fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade800.withAlpha(200),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Title oben
              const Column(
                children: [
                  Icon(
                    Icons.casino_outlined,
                    size: 64,
                    color: Colors.yellow,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "LOTTOGENERATOR V4",
                    style: TextStyle(
                      color: Colors.yellow,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Slot Machine
              _buildSlotMachine(),
              
              const SizedBox(height: 40),
              
              // Status & Controls
              _buildStatusIndicator(),
              
              // Info Footer
              const SizedBox(height: 40),
              const Text(
                "Offline Lotto Analyse • 6aus49 & Eurojackpot",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
