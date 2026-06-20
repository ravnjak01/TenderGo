import 'package:flutter/material.dart';
import 'package:tendergo/admin/admin-panel-v2/screens/admin_categories_panel.dart';
import 'package:tendergo/admin/admin-panel-v2/screens/admin_dashboard_panel.dart';
import 'package:tendergo/admin/admin-panel-v2/screens/admin_locations_panel.dart';
import 'package:tendergo/admin/admin-panel-v2/screens/admin_report_panel.dart';
import 'package:tendergo/admin/admin-panel-v2/screens/admin_tenders_panel.dart';
import 'package:tendergo/admin/admin-panel-v2/screens/admin_users_panel.dart';

class MainAdminLayout extends StatefulWidget {
  const MainAdminLayout({super.key});

  @override
  State<MainAdminLayout> createState() => _MainAdminLayoutState();
}

class _MainAdminLayoutState extends State<MainAdminLayout> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    AdminDashboardPanel(),
    AdminUsersPanel(),
    AdminTendersPanel(),
    AdminCategoriesPanel(),
    AdminLocationsPanel(),
    AdminReportsPanel(),
  ];

  final List<String> titles = const [
    'Dashboard',
    'Korisnici',
    'Tenderi',
    'Kategorije',
    'Lokacije',
    'Izvještaji',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 240,
            color: const Color(0xFF1F2937),
            child: Column(
              children: [
                const SizedBox(height: 32),
                const Text(
                  'TenderGo Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),

                _sidebarItem(Icons.dashboard, 'Dashboard', 0),
                _sidebarItem(Icons.people, 'Korisnici', 1),
                _sidebarItem(Icons.work, 'Tenderi', 2),
                _sidebarItem(Icons.category, 'Kategorije', 3),
                _sidebarItem(Icons.location_on, 'Lokacije', 4),
                _sidebarItem(Icons.picture_as_pdf, 'Izvještaji', 5),

                const Spacer(),

                _sidebarItem(Icons.logout, 'Odjava', -1),
                const SizedBox(height: 16),
              ],
            ),
          ),

          Expanded(
            child: Container(
              color: const Color(0xFFF4F6F8),
              child: pages[selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String title, int index) {
    final isSelected = selectedIndex == index;

    return InkWell(
      onTap: () {
        if (index == -1) {
          // TODO: logout logic
          return;
        }

        setState(() {
          selectedIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF374151) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}