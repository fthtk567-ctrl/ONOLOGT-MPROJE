import 'package:flutter/material.dart';
import 'courier_home_screen.dart';
import 'earnings_screen.dart';
import 'courier_profile_screen.dart';

class CourierNavigationScreen extends StatefulWidget {
  const CourierNavigationScreen({super.key});

  @override
  State<CourierNavigationScreen> createState() => _CourierNavigationScreenState();
}

class _CourierNavigationScreenState extends State<CourierNavigationScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const CourierHomeScreen(),
    const EarningsScreen(),
    const CourierProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).primaryColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.delivery_dining),
            label: 'Teslimatlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Kazançlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}