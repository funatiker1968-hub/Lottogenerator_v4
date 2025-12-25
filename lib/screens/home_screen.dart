import 'package:flutter/material.dart';
import './lotto6/lotto6_screen.dart';
import './database_status_screen.dart';
import './home_tiles_block.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeTilesBlock(
      lottoCountdown: '3d 12h',
      euroCountdown: '2d 18h',
      lottoLines: ['1', '2', '3', '4', '5'],
      euroLines: ['1', '2', '3'],
      isPortrait: true,
    ),
    const Lotto6Screen(),
    const DatabaseStatusScreen(),
  ];

  final List<String> _titles = [
    'Lotto Generator',
    'Lotto 6aus49',
    'Datenbank Status',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        centerTitle: true,
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.casino),
            label: 'Lotto 6aus49',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storage),
            label: 'Datenbank',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
