import 'package:flutter/material.dart';

class AppRoutes {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const String login = '/login';
  static const String adminDashboard = '/admin-dashboard';
  static const String adminTender = '/admin-tender';
  static const String adminUsers = '/admin-users';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      AppRoutes.login: (context) => const AdminPanelV2LoginScreen(),
      AppRoutes.adminDashboard: (context) => const AdminPanelV2DashboardScreen(),
      AppRoutes.adminTender: (context) => const AdminPanelV2TenderScreen(),
      AppRoutes.adminUsers: (context) => const AdminPanelV2UsersScreen(),
    };
  }
}

class AdminPanelV2LoginScreen extends StatelessWidget {
  const AdminPanelV2LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Login')),
      body: const Center(child: Text('Admin Panel v2 Login Screen')),
    );
  }
}

class AdminPanelV2DashboardScreen extends StatelessWidget {
  const AdminPanelV2DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: const Center(child: Text('Admin Panel v2 Dashboard Screen')),
    );
  }
}

class AdminPanelV2TenderScreen extends StatelessWidget {
  const AdminPanelV2TenderScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Tender')),
      body: const Center(child: Text('Admin Panel v2 Tender Screen')),
    );
  }
}

class AdminPanelV2UsersScreen extends StatelessWidget {
  const AdminPanelV2UsersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Users')),
      body: const Center(child: Text('Admin Panel v2 Users Screen')),
    );
  }
}
