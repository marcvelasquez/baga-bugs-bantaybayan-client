import 'package:flutter/material.dart';

class BantayBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BantayBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1a1621),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withOpacity(0.4),
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.warning_amber_rounded),
              activeIcon: Icon(Icons.warning_rounded),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.checklist_rounded),
              activeIcon: Icon(Icons.checklist_rounded),
              label: 'Checklist',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book),
              label: 'Handbook',
            ),
          ],
        ),
      ),
    );
  }
}
