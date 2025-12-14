import 'package:flutter/material.dart';

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
      backgroundColor: Colors.blue.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text(
                "Hinweis zur Nutzung",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(0, 0, 0, 0.87),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              const Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    """                                                                   
Diese App dient ausschließlich der zufälligen Generierung von Zahlen für Lotto 6aus49 und Eurojackpot.                                                                               
Sie basiert auf rein zufälligen mathematischen Verfahren und bietet keinerlei Gewinngarantie oder Verbesserung von Gewinnchancen.                                                                                                                                               
Lotto ist ein Glücksspiel. Bitte spiele verantwortungsbewusst.                             
Spielteilnahme erst ab 18 Jahren.                                                                                                                                                     
Diese App steht in keinerlei Verbindung zu staatlichen oder privaten Lotteriegesellschaften.                                                                                          
Alle Logos, Namen und Marken gehören den jeweiligen Inhabern.                                                                                                                         
Mit „Ich akzeptiere“ bestätigst du, dass du diesen Hinweis verstanden hast.                                                                                                           
Bei Ablehnung wird die App sofort geschlossen.                                                                 
""",
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.35,
                      color: Color.fromRGBO(0, 0, 0, 0.87),
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onDecline,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        "Ablehnen",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        "Ich akzeptiere",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
