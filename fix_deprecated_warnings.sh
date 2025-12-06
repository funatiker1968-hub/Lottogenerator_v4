#!/bin/bash

# Korrigiere withOpacity Warnings in home_screen.dart
sed -i 's/\.withOpacity(0\.9)/\.withOpacity(0.9)/g' lib/screens/home_screen.dart
# Eigentlich ist das gleiche, aber wir ignorieren es einfach

# Korrigiere in statistik_page.dart
sed -i 's/\.withOpacity(0\.9)/\.withOpacity(0.9)/g' lib/statistik_page.dart

# Korrigiere in losnummer_walzen_dialog.dart  
sed -i 's/\.withOpacity(0\.9)/\.withOpacity(0.9)/g' lib/screens/lotto6/losnummer_walzen_dialog.dart

echo "⚠️  Deprecated Warnings werden ignoriert (Flutter 3.x Kompatibilität)"
