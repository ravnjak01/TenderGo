import 'package:flutter/material.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/models/dto/location_dto.dart';
import 'package:tendergo/shared/models/requests/location_filter_request.dart';
import 'package:tendergo/shared/services/location_service.dart';

class TenderLocationSection extends StatefulWidget {
  final LocationService locationService;
  final int? selectedLocationId;
  final ValueChanged<int?> onChanged;
  final String? Function(int?)? validator;

  const TenderLocationSection({
    super.key,
    required this.locationService,
    required this.selectedLocationId,
    required this.onChanged,
    this.validator,
  });

  @override
  State<TenderLocationSection> createState() => _TenderLocationSectionState();
}

class _TenderLocationSectionState extends State<TenderLocationSection> {
  bool _isLoading = true;
  bool _isLoadingCountry = false;
  String? _loadError;

  List<String> _countries = const [];
  List<LocationDto> _countryLocations = const [];
  List<String> _regions = const [];

  String? _selectedCountry;
  String? _selectedRegion;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final locations = await widget.locationService.getLocations(
        const LocationFilterRequest(),
      );
      if (!mounted) return;
      setState(() {
        _countries = LocationService.distinctCountries(locations);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _onCountryChanged(String? country) async {
    if (country == null) {
      setState(() {
        _selectedCountry = null;
        _selectedRegion = null;
        _countryLocations = const [];
        _regions = const [];
      });
      widget.onChanged(null);
      return;
    }

    setState(() {
      _selectedCountry = country;
      _selectedRegion = null;
      _countryLocations = const [];
      _regions = const [];
      _isLoadingCountry = true;
    });
    widget.onChanged(null);

    try {
      final locations = await widget.locationService.getLocations(
        LocationFilterRequest(country: country),
      );
      if (!mounted) return;
      setState(() {
        _countryLocations = locations;
        _regions = LocationService.distinctRegions(locations);
        _isLoadingCountry = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingCountry = false;
      });
    }
  }

  void _onRegionChanged(String? region) {
    setState(() => _selectedRegion = region);
    widget.onChanged(null);
  }

  List<LocationDto> get _filteredCities {
    var cities = List<LocationDto>.from(_countryLocations);
    if (_selectedRegion != null && _selectedRegion!.isNotEmpty) {
      cities = cities
          .where(
            (l) =>
                (l.region ?? '').toLowerCase() ==
                _selectedRegion!.toLowerCase(),
          )
          .toList();
    }
    cities.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return cities;
  }

  InputDecoration _dropdownDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
      ),
      filled: true,
      fillColor: AppColors.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildErrorState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 420;

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.error_outline,
                      size: 14,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _loadError!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: _loadCountries,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(64, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(fontSize: 12, color: AppColors.primary),
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            const Icon(Icons.error_outline, size: 14, color: AppColors.error),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _loadError!,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: _loadCountries,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(64, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Retry',
                style: TextStyle(fontSize: 12, color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          Center(
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      );
    }

    if (_loadError != null && _countries.isEmpty) {
      return _buildErrorState();
    }

    final cities = _filteredCities;
    final countrySelected = _selectedCountry != null;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300), // Trajanje animacije širenja
      curve: Curves.easeInOut, // Stil animacije (glatko ubrzanje i usporenje)
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. DROPDOWN ZA DRŽAVU - Uvijek vidljiv
          _buildLabel('Country *'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedCountry,
            isExpanded: true,
            menuMaxHeight: 280,
            decoration: _dropdownDecoration(hintText: 'Select country'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a country';
              }
              return null;
            },
            items: _countries
                .map(
                  (country) => DropdownMenuItem<String>(
                    value: country,
                    child: Text(country),
                  ),
                )
                .toList(),
            onChanged: _onCountryChanged,
          ),

          // 2. ANIMIRANI DIO ZA REGIJU
          // Prikazuje se ili loader ili dropdown tek kad je država selektovana
          if (countrySelected) ...[
            const SizedBox(height: 16),
            if (_isLoadingCountry)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              )
            else ...[
              _buildLabel('Region (optional)'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                initialValue: _selectedRegion,
                isExpanded: true,
                menuMaxHeight: 280,
                decoration: _dropdownDecoration(hintText: 'Any region'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Any region'),
                  ),
                  ..._regions.map(
                    (region) => DropdownMenuItem<String?>(
                      value: region,
                      child: Text(region),
                    ),
                  ),
                ],
                onChanged: _onRegionChanged,
              ),
            ],
          ],

          if (countrySelected && !_isLoadingCountry) ...[
            const SizedBox(height: 16),
            _buildLabel('City *'),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: cities.any((c) => c.id == widget.selectedLocationId)
                  ? widget.selectedLocationId
                  : null,
              isExpanded: true,
              menuMaxHeight: 280,
              decoration: _dropdownDecoration(hintText: 'Select city'),
              items: cities
                  .map(
                    (location) => DropdownMenuItem<int>(
                      value: location.id,
                      child: Text(location.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => widget.onChanged(value),
              validator: widget.validator,
              selectedItemBuilder: (context) {
                return cities
                    .map(
                      (location) => Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          // Ako tvoj LocationDto ima displayLabel (npr. "Sarajevo, BiH"), ostavi ga ovdje
                          location.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList();
              },
            ),
          ],
        ],
      ),
    );
  }
}
