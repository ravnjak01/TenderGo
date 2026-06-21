import 'package:flutter/material.dart';
import 'package:tendergo/admin/routes/routes.dart';
import 'package:tendergo/shared/models/dto/admin_report_overview_dto.dart';
import 'package:tendergo/shared/models/dto/location_dto.dart';
import 'package:tendergo/shared/models/requests/location_filter_request.dart';
import 'package:tendergo/shared/services/admin_report_service.dart';
import 'package:tendergo/shared/services/dio_client.dart';
import 'package:tendergo/shared/services/location_service.dart';

class AdminReportsPanel extends StatefulWidget {
  const AdminReportsPanel({super.key});

  @override
  State<AdminReportsPanel> createState() => _AdminReportsPanelState();
}

class _AdminReportsPanelState extends State<AdminReportsPanel> {
  late final AdminReportService _reportService;
  late final LocationService _locationService;
  AdminReportOverviewDto? _overview;
  List<LocationDto> _locations = [];
  int? _selectedLocationId;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isLoading = true;
  bool _isGenerating = false;
  String? _error;
  String? _generatorError;

  @override
  void initState() {
    super.initState();
    _reportService = AdminReportService(DioClient.getDio());
    _locationService = LocationService(DioClient.getDio());
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Future.wait([_loadOverview(), _loadLocations()]);
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

  Future<void> _loadOverview() async {
    _overview = await _reportService.getOverview();
  }

  Future<void> _loadLocations() async {
    final result = await _locationService.getLocations(
      const LocationFilterRequest(),
    );

    _locations = result
      ..sort((a, b) => a.displayLabel.toLowerCase().compareTo(b.displayLabel.toLowerCase()));
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom
          ? (_fromDate ?? now)
          : (_toDate ?? (_fromDate ?? now)),
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );

    if (picked == null) return;

    setState(() {
      if (isFrom) {
        _fromDate = DateTime(picked.year, picked.month, picked.day);
      } else {
        _toDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      }
    });
  }

  Future<void> _generateReport() async {
    setState(() {
      _generatorError = null;
    });

    if (_selectedLocationId == null) {
      setState(() => _generatorError = 'Odaberite lokaciju.');
      return;
    }
    if (_fromDate == null) {
      setState(() => _generatorError = 'Odaberite početni datum.');
      return;
    }
    if (_toDate == null) {
      setState(() => _generatorError = 'Odaberite završni datum.');
      return;
    }
    if (_fromDate!.isAfter(_toDate!)) {
      setState(() => _generatorError = 'Početni datum ne može biti poslije završnog.');
      return;
    }

    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final bytes = await _reportService.fetchLocationReportPdf(
        locationId: _selectedLocationId!,
        from: _fromDate!,
        to: _toDate!,
      );

      if (!mounted) return;
      setState(() => _isGenerating = false);

      if (bytes != null && bytes.isNotEmpty) {
        final location = _locations.firstWhere(
          (location) => location.id == _selectedLocationId,
          orElse: () => LocationDto(id: _selectedLocationId!, name: 'Odabrana lokacija', country: '', region: null),
        );

        Navigator.of(context).pushNamed(
          AppRoutes.pdfViewer,
          arguments: {
            'pdfBytes': bytes,
            'title': 'Izvještaj - ${location.displayLabel}',
          },
        );
      } else {
        setState(() => _generatorError = 'Greška pri generisanju izvještaja.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _generatorError = e.toString();
      });
    }
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(right: 12, bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4B5563),
        ),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? value, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: Text(
            value == null
                ? label
                : '${value.day.toString().padLeft(2, '0')} / ${value.month.toString().padLeft(2, '0')} / ${value.year}',
            style: TextStyle(
              color: value == null ? const Color(0xFF9CA3AF) : const Color(0xFF111827),
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Greška: $_error'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Izvještaji',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMetricCard(
                            'Ukupna vrijednost tendera',
                            _overview?.totalTenderValue.toStringAsFixed(2) ?? '0.00',
                            const Color(0xFF2563EB),
                          ),
                          _buildMetricCard(
                            'Postotak realizacije',
                            '${_overview?.tenderRealizationPercentage.toStringAsFixed(1)} %',
                            const Color(0xFF16A34A),
                          ),
                          _buildMetricCard(
                            'Broj otkazanih tendera',
                            '${_overview?.cancelledTenderCount ?? 0}',
                            const Color(0xFFF59E0B),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Generiši PDF izvještaj',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildFieldLabel('Lokacija'),
                            DropdownButtonFormField<int>(
                              isExpanded: true,
                              value: _selectedLocationId,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                                ),
                              ),
                              items: _locations.map((location) {
                                return DropdownMenuItem<int>(
                                  value: location.id,
                                  child: Text(location.displayLabel),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedLocationId = value;
                                });
                              },
                              hint: const Text('Odaberite lokaciju'),
                            ),
                            const SizedBox(height: 16),
                            _buildFieldLabel('Period'),
                            Row(
                              children: [
                                _buildDateField('Od datuma', _fromDate, () => _pickDate(isFrom: true)),
                                const SizedBox(width: 12),
                                _buildDateField('Do datuma', _toDate, () => _pickDate(isFrom: false)),
                              ],
                            ),
                            if (_generatorError != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _generatorError!,
                                style: const TextStyle(color: Color(0xFFB91C1C)),
                              ),
                            ],
                            const SizedBox(height: 20),
                            SizedBox(
                              width: 220,
                              child: ElevatedButton(
                                onPressed: _isGenerating ? null : _generateReport,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  child: _isGenerating
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Text('Generiši PDF'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
