import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // FIX: Für SystemNavigator

class DisclaimerScreen extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const DisclaimerScreen({
    super.key,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(240, 248, 255, 1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header mit Warnsymbol
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 0, 0, 25), // RGBO statt withOpacity
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color.fromRGBO(255, 0, 0, 76)),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 64,
                      color: Colors.red,
                    ),
                    SizedBox(height: 12),
                    Text(
                      "WICHTIGER HINWEIS",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Scrollbarer Textinhalt
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 13),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const Text(
                          "Rechtlicher Hinweis",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(0, 0, 0, 0.87),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Diese App dient ausschließlich zu Unterhaltungs- und Informationszwecken.\n\n"
                          "1. KEINE GEWÄHR: Die App erhebt keinen Anspruch auf Richtigkeit oder Vollständigkeit.\n\n"
                          "2. KEINE GEWINNVORHERSAGE: Lottozahlen sind zufällig. Die App kann Gewinne nicht vorhersagen.\n\n"
                          "3. SPIELEN MIT VERANTWORTUNG: Setzen Sie nur Geld ein, das Sie verlieren können.\n\n"
                          "4. MINDESTALTER: Sie müssen mindestens 18 Jahre alt sein.\n\n"
                          "5. NUTZUNG AUF EIGENE GEFAHR: Die Entwickler übernehmen keine Haftung.\n\n"
                          "Die Nutzung der App setzt voraus, dass Sie diesen Bedingungen zustimmen.",
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Color.fromRGBO(0, 0, 0, 0.87),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Checkbox(
                              value: false,
                              onChanged: null,
                              fillColor: WidgetStateProperty.resolveWith<Color>(
                                (Set<WidgetState> states) { // FIX: WidgetState statt MaterialState
                                  return Colors.grey.shade300;
                                },
                              ),
                            ),
                            const Expanded(
                              child: Text(
                                "Ich bestätige, dass ich 18 Jahre oder älter bin",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // App SOFORT beenden
                        SystemNavigator.pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cancel, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "ABLEHNEN & APP BEENDEN",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "ICH AKZEPTIERE",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
