#!/bin/bash

echo "🔍 Prüfe strukturelle Fehler in database_status_screen.dart..."

# 1. Prüfe ob die Klasse korrekt definiert ist
echo "1. Klassen-Definition:"
grep -n "class _DatabaseStatusScreenState" lib/screens/database_status_screen.dart

# 2. Prüfe ob alle benötigten Variablen definiert sind
echo ""
echo "2. Fehlende Variablen laut Fehlermeldungen:"
echo "   - _loading: $(grep -n "_loading" lib/screens/database_status_screen.dart | head -2)"
echo "   - _stats: $(grep -n "_stats" lib/screens/database_status_screen.dart | head -2)"
echo "   - _logs: $(grep -n "_logs" lib/screens/database_status_screen.dart | head -2)"
echo "   - _scrollController: $(grep -n "_scrollController" lib/screens/database_status_screen.dart | head -2)"

# 3. Prüfe die _addLog Methode Signatur
echo ""
echo "3. _addLog Methoden-Signatur:"
grep -n -A5 "void _addLog" lib/screens/database_status_screen.dart

# 4. Zeige die ersten 50 Zeilen der Datei
echo ""
echo "4. Datei-Start (erste 50 Zeilen):"
head -50 lib/screens/database_status_screen.dart
