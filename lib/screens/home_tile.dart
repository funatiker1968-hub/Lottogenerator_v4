import 'package:flutter/material.dart';

class HomeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String drawDaysText;
  final String countdownText;
  final List<String> lastDrawLines;
  final Color color;
  final Color textColor;
  final bool hatEchteDaten;
  final VoidCallback onTap;

  const HomeTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.drawDaysText,
    required this.countdownText,
    required this.lastDrawLines,
    required this.color,
    required this.textColor,
    required this.hatEchteDaten,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shadow = [
      BoxShadow(
        color: Colors.black.withOpacity(0.20),
        blurRadius: 18,
        spreadRadius: 2,
        offset: const Offset(4, 8),
      ),
    ];

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: shadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titel + LIVE-Indikator
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (hatEchteDaten)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Untertitel
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 15,
                  color: textColor.withOpacity(0.9),
                ),
              ),

              const SizedBox(height: 12),

              // Ziehungen
              Text(
                hatEchteDaten ? 'Aktuelle Ziehungen:' : 'Beispiel-Ziehungen:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textColor.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 4),

              for (final line in lastDrawLines)
                Text(
                  line,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withOpacity(0.9),
                  ),
                ),

              const Spacer(),

              // Ziehungsinfo + Countdown
              Text(
                drawDaysText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textColor.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                countdownText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
