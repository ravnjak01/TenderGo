import 'package:flutter/material.dart';
import 'package:tendergo/shared/models/dto/location_dto.dart';
import 'package:tendergo/shared/models/requests/location_filter_request.dart';
import 'package:tendergo/shared/models/ui/location_filter_selection.dart';
import 'package:tendergo/shared/services/location_service.dart';

enum _PickerStep { country, region, city }

class LocationPickerSheet extends StatefulWidget {
  final LocationService locationService;

  const LocationPickerSheet({
    super.key,
    required this.locationService,
  });

  static Future<LocationFilterSelection?> show(
    BuildContext context, {
    required LocationService locationService,
  }) {
    return showModalBottomSheet<LocationFilterSelection?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => LocationPickerSheet(locationService: locationService),
    );
  }

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  _PickerStep _step = _PickerStep.country;

  bool _isLoading = true;
  String? _errorMessage;

  List<String> _countries = const [];
  List<LocationDto> _countryLocations = const [];
  String? _selectedCountry;
  String? _selectedRegion;
  List<String> _regions = const [];

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }


  Future<void> _loadCountries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final locations =
          await widget.locationService.getLocations(const LocationFilterRequest());
      if (!mounted) return;
      setState(() {
        _countries = LocationService.distinctCountries(locations);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCountryLocations(String country) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedCountry = country;
    });

    try {
      final locations = await widget.locationService.getLocations(
        LocationFilterRequest(country: country),
      );
      if (!mounted) return;
      setState(() {
        _countryLocations = locations;
        _regions = LocationService.distinctRegions(locations);
        _step = _PickerStep.region;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }


  void _openCityStep(String region) {
    setState(() {
      _selectedRegion = region;
      _step = _PickerStep.city;
    });
  }

  void _goBack() {
    setState(() {
      _errorMessage = null;
      switch (_step) {
        case _PickerStep.city:
          _step = _PickerStep.region;
          _selectedRegion = null;
        case _PickerStep.region:
          _step = _PickerStep.country;
          _selectedCountry = null;
          _countryLocations = const [];
          _regions = const [];
        case _PickerStep.country:
          break;
      }
    });
  }

  String get _title {
    switch (_step) {
      case _PickerStep.country:
        return 'Select country';
      case _PickerStep.region:
        return 'Select region';
      case _PickerStep.city:
        return 'Select city';
    }
  }

  List<LocationDto> get _citiesInRegion {
    if (_selectedRegion == null) return const [];
    return _countryLocations
        .where(
          (l) =>
              (l.region ?? '').toLowerCase() ==
              _selectedRegion!.toLowerCase(),
        )
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.55,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
              child: Row(
                children: [
                  if (_step != _PickerStep.country)
                    IconButton(
                      onPressed: _goBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Text(
                      _title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _step == _PickerStep.country
                    ? _loadCountries
                    : () => _loadCountryLocations(_selectedCountry!),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    switch (_step) {
      case _PickerStep.country:
        return _buildCountryList();
      case _PickerStep.region:
        return _buildRegionList();
      case _PickerStep.city:
        return _buildCityList();
    }
  }

  Widget _buildCountryList() {
    if (_countries.isEmpty) {
      return const Center(child: Text('No countries found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _countries.length,
      itemBuilder: (context, index) {
        final country = _countries[index];
        return ListTile(
          leading: const Icon(Icons.public_rounded),
          title: Text(country),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _loadCountryLocations(country),
        );
      },
    );
  }

  Widget _buildRegionList() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        ListTile(
          leading: const Icon(Icons.flag_rounded, color: Color(0xFF185FA5)),
          title: Text('Entire country ($_selectedCountry)'),
          subtitle: const Text('Show all tenders in this country'),
          onTap: () {
            Navigator.of(context).pop(
              LocationFilterSelection.countryOnly(_selectedCountry!),
            );
          },
        ),
        if (_regions.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Regions',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF5F5E5A),
              ),
            ),
          ),
          ..._regions.map(
            (region) => ListTile(
              leading: const Icon(Icons.map_outlined),
              title: Text(region),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _openCityStep(region),
            ),
          ),
        ],
        if (_regions.isEmpty)
          ..._countryLocations.map(
            (loc) => ListTile(
              leading: const Icon(Icons.location_city_outlined),
              title: Text(loc.name),
              onTap: () {
                Navigator.of(context).pop(LocationFilterSelection.city(loc));
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCityList() {
    final cities = _citiesInRegion;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        ListTile(
          leading: const Icon(Icons.map_rounded, color: Color(0xFF185FA5)),
          title: Text('Entire region ($_selectedRegion)'),
          subtitle: const Text('Show all tenders in this region'),
          onTap: () {
            Navigator.of(context).pop(
              LocationFilterSelection.region(
                country: _selectedCountry!,
                region: _selectedRegion!,
              ),
            );
          },
        ),
        if (cities.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('No cities found in this region')),
          )
        else ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Cities',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF5F5E5A),
              ),
            ),
          ),
          ...cities.map(
            (loc) => ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text(loc.name),
              subtitle: Text(_selectedCountry ?? ''),
              onTap: () {
                Navigator.of(context).pop(LocationFilterSelection.city(loc));
              },
            ),
          ),
        ],
      ],
    );
  }
}
