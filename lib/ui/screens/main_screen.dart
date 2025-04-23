// lib/ui/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/app_drawer.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  final Widget child;

  const MainScreen({
    Key? key,
    required this.child,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // If we're at the root/dashboard (first navigation item)
        if (_currentIndex == 0) {
          // Langsung keluar aplikasi tanpa konfirmasi
          SystemNavigator.pop(); // This will exit the app
          return false; // Prevent default back behavior
        }

        // For non-root pages, allow normal back button behavior
        return true;
      },
      child: Scaffold(
        body: widget.child, // Show the child widget passed through route
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
        drawer: AppDrawer(
          currentIndex: _currentIndex,
          onNavigate: _onTabTapped,
        ),
      ),
    );
  }
}