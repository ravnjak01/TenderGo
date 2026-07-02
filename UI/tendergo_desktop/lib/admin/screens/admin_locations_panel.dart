import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tendergo/shared/models/dto/location_dto.dart';
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
  Timer? _debounceTimer;

  List<LocationDto> _locations = [];
  Map<int, LocationStatsDto> _statsByLocation = {};
  LocationOverviewDto? _overview;
  bool _isLoading = true;
  String? _error;
  bool? _selectedActiveFilter;
int _currentPage = 1;
int _pageSize = 5; 
int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _locationService = LocationService(DioClient.getDio());
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData({String searchTerm = '', bool refreshOverview = false, bool isNewSearch = false}) async {
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
        _fetchLocations(searchTerm: searchTerm, isNewSearch: isNewSearch),
      ]);
    } else {
      await _fetchLocations(searchTerm: searchTerm, isNewSearch: isNewSearch);
    }

    if (shouldShowLoader) {
      setState(() {
        _isLoading = false;
      });
    }
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

Future<void> _fetchLocations({String searchTerm = '', bool isNewSearch = false}) async {
  if (isNewSearch) {
    _currentPage = 1;
  }

  setState(() {
    _isLoading = true;
    _error = null;
  });

  try {
    final request = LocationSearchRequest(
      searchTerm: searchTerm.isEmpty ? null : searchTerm,
      page: _currentPage,
      pageSize: _pageSize,
      isActive: _selectedActiveFilter,
    );

    final pagedResult = await _locationService.search(request);
    
    if (!mounted) return;

    setState(() {
      _locations = pagedResult.result;       
      _totalCount = pagedResult.totalCount; 
      _currentPage = pagedResult.page;       
      _pageSize = pagedResult.pageSize;     
      _isLoading = false;
    });
  } catch (e) {
    if (!mounted) return;
    setState(() {
      _error = e.toString();
      _isLoading = false;
    });
  }
}
  int _activeTenderCount(LocationDto location) {
    return _statsByLocation[location.id]?.tenderCount ?? 0;
  }

  bool _hasActiveTenders(LocationDto location) {
    return _activeTenderCount(location) > 0;
  }

  Future<void> _refreshData() {
    return _loadData(
      searchTerm: _searchController.text.trim(),
      refreshOverview: true,
      isNewSearch: true,
    );
  }
  
  Future<void> _showAddLocationDialog() async {
    final nameController = TextEditingController();
    final countryController = TextEditingController();
    final regionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dodaj lokaciju'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Naziv lokacije'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Naziv lokacije je obavezan.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: countryController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Drzava je obavezna.';
                }
                return null;
              },
              decoration: const InputDecoration(labelText: 'Država'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: regionController,
              decoration: const InputDecoration(labelText: 'Region (opcionalno)'),
            ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
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
      await _refreshData();
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
      await _refreshData();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _activateLocation(LocationDto location) async {
    final confirmed = await AppDialogs.showConfirm(
      context: context,
      title: 'Aktiviraj lokaciju',
      content: 'Da li ste sigurni da \u017eelite aktivirati lokaciju "${location.displayLabel}"?',
      cancelLabel: 'Otka\u017ei',
      confirmLabel: 'Aktiviraj',
      isDestructive: false,
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _locationService.activateLocation(location.id);
      await _refreshData();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteLocation(LocationDto location) async {
    if (_hasActiveTenders(location)) {
      final shouldDeactivate = await AppDialogs.showConfirm(
        context: context,
        title: 'Lokacija ima aktivne tendere',
        content: 'Ova lokacija se ne može obrisati jer je povezana sa aktivnim tenderima. '
                 'Da li želite da je deaktivirate umjesto brisanja?',
        cancelLabel: 'Otkaži',
        confirmLabel: 'Deaktiviraj',
        isDestructive: false, 
      );

      if (!shouldDeactivate) return;

      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        await _locationService.deactivateLocation(location.id);
        await _refreshData();
      } catch (e) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
      return; 
    }

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
      await _refreshData();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
  if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
  
  _debounceTimer = Timer(const Duration(milliseconds: 400), () {
    _loadData(searchTerm: value.trim(), isNewSearch: true);
  });
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

  final totalPages = (_totalCount / _pageSize).ceil();
  final hasPreviousPage = _currentPage > 1;
  final hasNextPage = _currentPage < totalPages;

  return Container(
    color: const Color(0xFFF8FAFC),
    width: double.infinity,
    padding: const EdgeInsets.all(32.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TOP NASLOV I KORISNIK
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

        // FILTERI I PRETRAGA
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
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: Color(0xFF94A3B8)),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                          _fetchLocations(searchTerm: '', isNewSearch: true);
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {});
                    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
                    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
                  _fetchLocations(searchTerm: value.trim(), isNewSearch: true);
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 18),
            SizedBox(
              height: 40,
              child: SegmentedButton<bool?>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  backgroundColor: Colors.white,
                  selectedBackgroundColor: const Color(0xFFEFF6FF),
                  selectedForegroundColor: const Color(0xFF2563EB),
                  foregroundColor: const Color(0xFF64748B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                segments: const <ButtonSegment<bool?>>[
                  ButtonSegment<bool?>(
                    value: null,
                    label: Text('Sve', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                  ButtonSegment<bool?>(
                    value: true,
                    label: Text('Aktivne', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                  ButtonSegment<bool?>(
                    value: false,
                    label: Text('Neaktivne', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                ],
                selected: <bool?>{_selectedActiveFilter},
                onSelectionChanged: (Set<bool?> newSelection) {
                  setState(() {
                    _selectedActiveFilter = newSelection.first;
                  });
                  _fetchLocations(searchTerm: '', isNewSearch: true);
                },
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

        // STATISTIČKE KARTICE (OVERVIEW)
        if (overview != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _overviewCard('Ukupno lokacija', overview.totalLocations, const Color(0xFF2563EB)),
              _overviewCard('Aktivne lokacije', overview.activeLocations, const Color(0xFF16A34A)),
              _overviewCard('Neaktivne lokacije', overview.inactiveLocations, const Color(0xFFF59E0B)),
            ],
          ),
        const SizedBox(height: 24),

        // TABELA I PAGINACIJA
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
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // 1. ZAGLAVLJE PODEŠENE TABELE (HEADER ROW)
                          Container(
                            color: const Color(0xFFF8FAFC),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: const Row(
                              children: [
                                Expanded(flex: 3, child: Text('Lokacija', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                                Expanded(flex: 2, child: Text('Država', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                                Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                                Expanded(flex: 2, child: Text('Broj svih tendera', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                                Expanded(flex: 2, child: Text('Akcije', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),

                          // 2. REDOVI TABELE (BODY)
                          Expanded(
                            child: _locations.isEmpty
                                ? const Center(child: Text('Nema pronađenih lokacija.', style: TextStyle(color: Color(0xFF64748B))))
                                : ListView.separated(
                                    itemCount: _locations.length,
                                    separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                    itemBuilder: (context, index) {
                                      final location = _locations[index];
                                      final tenderCount = _activeTenderCount(location);

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                location.region != null && location.region!.isNotEmpty
                                                    ? '${location.name}, ${location.region}'
                                                    : location.name,
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(location.country, style: const TextStyle(color: Color(0xFF475569))),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Container(
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
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFEFF6FF),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    tenderCount.toString(),
                                                    style: const TextStyle(color: Color(0xFF2563EB), fontSize: 12, fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  OutlinedButton(
                                                    onPressed: () => _showEditLocationDialog(location),
                                                    style: OutlinedButton.styleFrom(
                                                      minimumSize: const Size(65, 26),
                                                      padding: EdgeInsets.zero,
                                                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                                    ),
                                                    child: const Text('Uredi', style: TextStyle(color: Color(0xFF475569), fontSize: 11)),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  OutlinedButton(
                                                    onPressed: () => location.isActive ? _deleteLocation(location) : _activateLocation(location),
                                                    style: OutlinedButton.styleFrom(
                                                      minimumSize: const Size(65, 26),
                                                      padding: EdgeInsets.zero,
                                                      side: BorderSide(color: location.isActive ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0)),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                                    ),
                                                    child: Text(
                                                      location.isActive ? 'Obriši' : 'Aktiviraj',
                                                      style: TextStyle(
                                                        color: location.isActive ? const Color(0xFFEF4444) : const Color(0xFF16A34A),
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
Container(
  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
  color: const Color(0xFFF8FAFC),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        _totalCount == 0 
            ? 'Nema pronađenih stavki'
            : 'Prikazano ${((_currentPage - 1) * _pageSize) + 1} - ${(_currentPage * _pageSize) > _totalCount ? _totalCount : (_currentPage * _pageSize)} od $_totalCount stavki',
        style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
      ),
      Row(
        children: [
          // Gumb Prethodna
          OutlinedButton(
            onPressed: hasPreviousPage
                ? () {
                    setState(() => _currentPage--);
                    _loadData(searchTerm: _searchController.text);
                  }
                : null,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
           child: const Icon(Icons.arrow_back_ios, size: 14, color: Color(0xFF475569)),
          ),
          const SizedBox(width: 8),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Stranica $_currentPage od ${totalPages == 0 ? 1 : totalPages}',
              style: const TextStyle(
                fontWeight: FontWeight.w600, 
                fontSize: 14, 
                color: Color(0xFF1E293B)
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          OutlinedButton(
            onPressed: hasNextPage
                ? () {
                    setState(() => _currentPage++);
                    _loadData(searchTerm: _searchController.text);
                  }
                : null,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            child: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF475569)),
          ),
        ],
      ),
    ],
  ),
),
                        ],
                      ),
                    ),
        ),
      ],
    ),
  );
}
}
