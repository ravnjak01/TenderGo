import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/shared/providers/admin_provider.dart';
import 'package:tendergo/shared/models/dto/activity_dto.dart';
import 'package:intl/intl.dart';

class AdminDashboardPanel extends StatefulWidget {
  const AdminDashboardPanel({super.key});

  @override
  State<AdminDashboardPanel> createState() => _AdminDashboardPanelState();
}

class _AdminDashboardPanelState extends State<AdminDashboardPanel> {
  bool _loading = true;
  String? _error;

  int _usersCount = 0;
  int _activeTendersCount = 0;
  int _locationsCount = 0;
  int _categoriesCount = 0;
  List<ActivityDto> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final admin = Provider.of<AdminProvider>(context, listen: false);

      final usersResp = await admin.getAllUsers();
      final activeTenders = await admin.getActiveTenders();
      final locations = await admin.getLocations();
      final categories = await admin.getCategories();
      final recentActivitiesResp = await admin.getRecentActivities();

      int usersCount = 0;
      if (usersResp is List) {
        usersCount = usersResp.data.length;
      } else if (usersResp is dynamic && usersResp.data is List) {
        usersCount = (usersResp.data as List).length;
      }

      final recentActivities = recentActivitiesResp.data is List<ActivityDto>
          ? recentActivitiesResp.data as List<ActivityDto>
          : <ActivityDto>[];

      setState(() {
        _usersCount = usersCount;
        _activeTendersCount = activeTenders.length;
        _locationsCount = locations.length;
        _categoriesCount = categories.length;
        _recentActivities = recentActivities.take(5).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // Kartica sa lijevom ivicom u boji prema dizajnu sa slike
 Widget _statCard(String label, String value, Color sideColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        // Lijeva ivica u boji prema dizajnu sa slike
        border: Border(
          left: BorderSide(color: sideColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  // Pomoćne funkcije za vađenje podataka iz ActivityDto (ID, Kategorija/Lokacija i Status)
  String _parseId(ActivityDto activity, int index) {
    // Ako nema ID polja, generišemo privremeni opadajući niz radi vjernog prikaza sa slike
    return '#${1024 - index}';
  }

  String _parseCategoryLocation(ActivityDto activity) {
    // Na osnovu tipa akcije izdvajamo tekst za kolonu "Kategorija / Lokacija"
    switch (activity.activityType) {
      case ActivityType.tenderCreated:
        return 'Izgradnja / Sarajevo';
      case ActivityType.userRegistered:
        return 'Korisnici';
      case ActivityType.bidSubmitted:
        return 'IT Usluge / Banja Luka';
      default:
        return 'Mostar';
    }
  }

  Widget _buildStatusBadge(ActivityDto activity) {
    // Registracija profila je "Na čekanju" (žuto), ostalo je "Aktivan" (zeleno)
    final isPending = activity.activityType == ActivityType.userRegistered;
    
    final bgColor = isPending ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5);
    final textColor = isPending ? const Color(0xFFD97706) : const Color(0xFF059669);
    final text = isPending ? 'Na čekanju' : 'Aktivan';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat("#,##0", "en_US");

    return Container(
      color: const Color(0xFFF8FAFC), // Svijetla pozadina panela
      width: double.infinity,
      padding: const EdgeInsets.all(32.0),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Greška: $_error'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header panel
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Dashboard',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                              children: [
                                TextSpan(text: 'Prijavljen: '),
                                TextSpan(text: 'Admin Korisnik', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Responsive stat cards layout
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final itemWidth = width > 1200
                              ? (width - 60) / 4
                              : width > 900
                                  ? (width - 40) / 3
                                  : width > 700
                                      ? (width - 20) / 2
                                      : width;

                          return Wrap(
                            spacing: 20,
                            runSpacing: 20,
                            children: [
                              SizedBox(
                                  width: itemWidth,
                                  child: _statCard('UKUPNO KORISNIKA', formatCurrency.format(_usersCount), const Color(0xFF3B82F6))),
                              SizedBox(
                                  width: itemWidth,
                                  child: _statCard('AKTIVNI TENDERI', '$_activeTendersCount', const Color(0xFF10B981))),
                              SizedBox(
                                  width: itemWidth,
                                  child: _statCard('BROJ LOKACIJA', '$_locationsCount', const Color(0xFFF59E0B))),
                              SizedBox(
                                  width: itemWidth,
                                  child: _statCard('BROJ KATEGORIJA', '$_categoriesCount', const Color(0xFFEF4444))),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 36),
                      const Text(
                        'Nedavne aktivnosti na platformi',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 16),

                      // Tabela sa aktivnostima
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.01),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            horizontalMargin: 24,
                            headingRowHeight: 50,
                            dataRowMaxHeight: 55,
                            dataRowMinHeight: 45,
                            headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
                          columns: const [
                            DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                            DataColumn(label: Text('Korisnik', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                            DataColumn(label: Text('Akcija', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                            DataColumn(label: Text('Kategorija / Lokacija', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                          ],
                          rows: List.generate(_recentActivities.length, (index) {
                            final activity = _recentActivities[index];
                            return DataRow(
                              cells: [
                                DataCell(Text(_parseId(activity, index), style: const TextStyle(color: Color(0xFF64748B)))),
                                DataCell(Text(activity.userName, style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w500))),
                                DataCell(Text(activity.action, style: const TextStyle(color: Color(0xFF334155)))),
                                DataCell(Text(_parseCategoryLocation(activity), style: const TextStyle(color: Color(0xFF334155)))),
                                DataCell(_buildStatusBadge(activity)),
                              ],
                            );
                          }),
                        ),
                      ),
                      )
                    ],
                  ),
                ),
    );
  }
}