import 'package:flutter/material.dart';
import 'package:tendergo/shared/models/dto/location_dto.dart';
import 'package:tendergo/shared/models/requests/location_filter_request.dart';
import 'package:tendergo/shared/models/requests/location_insert_request.dart';
import 'package:tendergo/shared/models/requests/location_search_request.dart';
import 'package:tendergo/shared/models/requests/location_update_request.dart';
import 'package:tendergo/shared/services/dio_client.dart';
import 'package:tendergo/shared/services/location_service.dart';
import 'package:tendergo/shared/widgets/common/app_dialogs.dart';

class AdminLocationsPanel extends StatefulWidget {
  const AdminLocationsPanel({super.key});

  @override
  State<AdminLocationsPanel> createState() => _AdminLocationsPanelState();
}

class _AdminLocationsPanelState extends State<AdminLocationsPanel> {
  final TextEditingController _searchController = TextEditingController();
  late final LocationService _locationService;

  List<LocationDto> _locations = [];
  Map<int, LocationStatsDto> _statsByLocation = {};
  LocationOverviewDto? _overview;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _locationService = LocationService(DioClient.getDio());
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData({String searchTerm = '', bool refreshOverview = false}) async {
    final shouldShowLoader = refreshOverview || (searchTerm.isEmpty && _locations.isEmpty);

    if (shouldShowLoader) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      if (refreshOverview || _locations.isEmpty) {
        await Future.wait([
          _fetchOverview(),
          _fetchStatistics(),
          _fetchLocations(searchTerm: searchTerm),
        ]);
      } else {
        await _fetchLocations(searchTerm: searchTerm);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchOverview() async {
    _overview = await _locationService.getLocationOverview();
  }

  Future<void> _fetchStatistics() async {
    final stats = await _locationService.getLocationStatistics();
    _statsByLocation = {for (var stat in stats) stat.locationId: stat};
  }

  Future<void> _fetchLocations({String searchTerm = ''}) async {
    _locations = await _locationService.getLocations(
      LocationFilterRequest(country: searchTerm),
      includeInactive: true,
    );
  }

  int _activeTenderCount(LocationDto location) {
    return _statsByLocation[location.id]?.tenderCount ?? 0;
  }

  bool _hasActiveTenders(LocationDto location) {
    return _activeTenderCount(location) > 0;
  }
  
  Future<void> _showAddLocationDialog() async {
    final nameController = TextEditingController();
    final countryController = TextEditingController();
    final regionController = TextEditingController();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dodaj lokaciju'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Naziv lokacije'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: countryController,
              decoration: const InputDecoration(labelText: 'Država'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: regionController,
              decoration: const InputDecoration(labelText: 'Region (opcionalno)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sačuvaj'),
          ),
        ],
      ),
    );

    if (shouldSave != true) return;

    final name = nameController.text.trim();
    final country = countryController.text.trim();
    final region = regionController.text.trim();

    if (name.isEmpty || country.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _locationService.insertLocation(
        LocationInsertRequest(
          name: name,
          country: country,
          region: region.isEmpty ? null : region,
        ),
      );
      await _loadData(searchTerm: _searchController.text, refreshOverview: true);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showEditLocationDialog(LocationDto location) async {
    final nameController = TextEditingController(text: location.name);
    final countryController = TextEditingController(text: location.country);
    final regionController = TextEditingController(text: location.region ?? '');

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uredi lokaciju'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Naziv lokacije'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: countryController,
              decoration: const InputDecoration(labelText: 'Država'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: regionController,
              decoration: const InputDecoration(labelText: 'Region (opcionalno)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sačuvaj'),
          ),
        ],
      ),
    );

    if (shouldSave != true) return;

    final name = nameController.text.trim();
    final country = countryController.text.trim();
    final region = regionController.text.trim();

    if (name.isEmpty || country.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _locationService.updateLocation(
        location.id,
        LocationUpdateRequest(
          name: name,
          country: country,
          region: region.isEmpty ? null : region,
        ),
      );
      await _loadData(searchTerm: _searchController.text, refreshOverview: true);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteLocation(LocationDto location) async {
    // 1. SLUČAJ: Lokacija ima aktivne tendere -> Nudimo deaktivaciju
    if (_hasActiveTenders(location)) {
      final shouldDeactivate = await AppDialogs.showConfirm(
        context: context,
        title: 'Lokacija ima aktivne tendere',
        content: 'Ova lokacija se ne može obrisati jer je povezana sa aktivnim tenderima. '
                 'Da li želite da je deaktivirate umjesto brisanja?',
        cancelLabel: 'Otkaži',
        confirmLabel: 'Deaktiviraj',
        isDestructive: false, // Može biti i true/false zavisno od UI dizajna
      );

      if (!shouldDeactivate) return;

      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        await _locationService.deactivateLocation(location.id);
        await _loadData(searchTerm: _searchController.text, refreshOverview: true);
      } catch (e) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
      return; // Prekidamo izvršavanje da ne ide na standardno brisanje
    }

    // 2. SLUČAJ: Lokacija nema aktivne tendere -> Standardno brisanje
    final confirmed = await AppDialogs.showConfirm(
      context: context,
      title: 'Potvrdi brisanje',
      content: 'Da li ste sigurni da želite obrisati lokaciju "${location.displayLabel}"?',
      cancelLabel: 'Otkaži',
      confirmLabel: 'Obriši',
      isDestructive: true,
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _locationService.deleteLocation(location.id);
      await _loadData(searchTerm: _searchController.text, refreshOverview: true);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _overviewCard(String title, int value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
            const SizedBox(height: 10),
            Text(
              value.toString(),
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final overview = _overview;

    return Container(
      color: const Color(0xFFF8FAFC),
      width: double.infinity,
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upravljanje lokacijama',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              RichText(
                text: const TextSpan(
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                  children: [
                    TextSpan(text: 'Prijavljen: '),
                    TextSpan(
                      text: 'Admin Korisnik',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
  controller: _searchController,
  decoration: InputDecoration(
    hintText: 'Pretraži lokacije...',
    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: InputBorder.none,
    // Dodajemo suffixIcon za brisanje teksta
    suffixIcon: _searchController.text.isNotEmpty
        ? IconButton(
            icon: const Icon(Icons.clear, size: 18, color: Color(0xFF94A3B8)),
            onPressed: () {
              _searchController.clear(); // Briše tekst iz kontrolera
              _loadData(searchTerm: ''); // Vraća sve rezultate
            },
          )
        : null,
  ),
  onChanged: (value) {
    // Ako obriše backspace-om do kraja, value će biti prazan string '' i povući će sve
    _loadData(searchTerm: value.trim());
  },
),
                ),
              ),
              const SizedBox(width: 18),
              ElevatedButton.icon(
                onPressed: _showAddLocationDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  'Dodaj novu lokaciju',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (overview != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _overviewCard('Ukupno lokacija', overview.totalLocations, const Color(0xFF2563EB)),
                _overviewCard('Aktivne lokacije', overview.activeLocations, const Color(0xFF16A34A)),
                _overviewCard('Neaktivne lokacije', overview.inactiveLocations, const Color(0xFFF59E0B)),
                _overviewCard('Aktivni tenderi', overview.locationWithActiveTenders, const Color(0xFFDB2777)),
              ],
            ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Greška pri učitavanju: $_error'))
                    : Container(
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
                          child: DataTable(
                            horizontalMargin: 24,
                            headingRowHeight: 55,
                            dataRowMaxHeight: 75,
                            dataRowMinHeight: 65,
                            headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
                            columns: const [
                              DataColumn(
                                label: Text(
                                  'Lokacija',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Država',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Status',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Aktivni tenderi',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Akcije',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                ),
                              ),
                            ],
                            rows: _locations.map((location) {
                              final tenderCount = _activeTenderCount(location);

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      location.region != null && location.region!.isNotEmpty
                                          ? '${location.name}, ${location.region}'
                                          : location.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      location.country,
                                      style: const TextStyle(color: Color(0xFF475569)),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: location.isActive ? const Color(0xFFE6FFFA) : const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        location.isActive ? 'Aktivna' : 'Neaktivna',
                                        style: TextStyle(
                                          color: location.isActive ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        tenderCount.toString(),
                                        style: const TextStyle(
                                          color: Color(0xFF2563EB),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          OutlinedButton(
                                            onPressed: () => _showEditLocationDialog(location),
                                            style: OutlinedButton.styleFrom(
                                              minimumSize: const Size(65, 26),
                                              padding: EdgeInsets.zero,
                                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                            ),
                                            child: const Text(
                                              'Uredi',
                                              style: TextStyle(color: Color(0xFF475569), fontSize: 11),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          OutlinedButton(
                                            onPressed: () => _deleteLocation(location),
                                            style: OutlinedButton.styleFrom(
                                              minimumSize: const Size(65, 26),
                                              padding: EdgeInsets.zero,
                                              side: const BorderSide(color: Color(0xFFFECACA)),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                            ),
                                            child: const Text(
                                              'Obriši',
                                              style: TextStyle(color: Color(0xFFEF4444), fontSize: 11),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
