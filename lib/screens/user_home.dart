import 'package:flutter/material.dart';

import '../data/app_store.dart';
import 'booking_list_screen.dart';
import 'help_screen.dart';
import 'login_screen.dart';
import 'product_screen.dart';
import 'profile_page.dart';
import 'purchase_screen.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  int selectedIndex = 0;

  List<Widget> get pages => [
        const ProductScreen(),
        const BookingListScreen(),
        const PurchaseScreen(),
        const HelpScreen(),
        ProfilePage(
          onLanguageChanged: () => setState(() {}),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (selectedIndex > 0) {
          setState(() => selectedIndex -= 1);
          return false;
        }
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        body: pages[selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.agriculture),
            label: AppStore.tr("Products", "பொருட்கள்"),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.book_online),
            label: AppStore.tr("Bookings", "பதிவுகள்"),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_cart),
            label: AppStore.tr("Purchases", "வாங்கியது"),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.help_outline),
            label: AppStore.tr("Help", "உதவி"),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: AppStore.tr("Profile", "சுயவிவரம்"),
          ),
        ],
        ),
      ),
    );
  }
}
