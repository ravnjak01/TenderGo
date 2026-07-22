import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/admin/screens/admin_tender_details_screen.dart';
import 'package:tendergo/shared/models/dto/admin_tender_dto.dart';
import 'package:tendergo/shared/models/dto/paged_result.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/enums/tenderstatus.dart';
import 'package:tendergo/shared/models/requests/admin_tender_search_request.dart';
import 'package:tendergo/shared/providers/tender_provider.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/shared/widgets/common/app_dialogs.dart';

class AdminTendersPanel extends StatefulWidget {
  const AdminTendersPanel({super.key});

  @override
  State<AdminTendersPanel> createState() => _AdminTendersPanelState();
}

class _AdminTendersPanelState extends State<AdminTendersPanel> {
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;

  List<AdminTenderDto> _tenders = [];

  // Paginacijske varijable
  int _currentPage = 1;
  int _pageSize = 5; 
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData({String searchTerm = '', bool isNewSearch = false}) async {
    if (isNewSearch) {
      _currentPage = 1;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final adminTenderService = context.read<TenderService>();

      final request = AdminTenderSearchRequest(
        searchTerm: searchTerm.isEmpty ? null : searchTerm,
        page: _currentPage,
        pageSize: _pageSize,
      );

      PagedResult<AdminTenderDto> pagedResult = await adminTenderService.search(request);

     


      if (!mounted) return;

      setState(() {
        _tenders = pagedResult.result;
        _totalCount = pagedResult.totalCount; 
        _currentPage = pagedResult.page;
        _pageSize = pagedResult.pageSize;
        _loading = false;
      });

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  } // Kraj _loadData metode

  void _onSearchChanged(String value) {
    _loadData(searchTerm: value, isNewSearch: true);
  }
  
  void _nextPage() {
    final int totalPages = (_totalCount / _pageSize).ceil();
    if (_currentPage < totalPages) {
      setState(() => _currentPage++);
      _loadData(searchTerm: _searchController.text);
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() => _currentPage--);
      _loadData(searchTerm: _searchController.text);
    }
  }


 Future<void> _showCancelDialog(BuildContext context, AdminTenderDto tender) async {
  final TextEditingController reasonController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Dijalog vraća uneseni razlog (String) ili null ako je korisnik odustao
  final String? reason = await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Potvrda otkazivanja'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Da li ste sigurni da želite otkazati tender "${tender.title}" ?',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Razlog otkazivanja *',
                  hintText: 'Unesite detaljan razlog zašto se tender otkazuje...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Razlog otkazivanja je obavezan.';
                  }
                  if (value.trim().length < 5) {
                    return 'Razlog mora imati najmanje 5 karaktera.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null), // Odustani
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(reasonController.text.trim());
              }
            },
            child: const Text('Otkaži tender'),
          ),
        ],
      );
    },
  );

  // Ako je korisnik unio razlog i potvrdio
  if (reason != null && reason.isNotEmpty && mounted) {
    setState(() => _loading = true);

    try {
      final tenderProvider = context.read<TenderProvider>(); 
      
      // Pozivamo provider koji šalje id i uneti razlog
      final success = await tenderProvider.cancelTender(tender.id, reason);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tender uspješno otkazan.')),
        );

        await _loadData(searchTerm: _searchController.text);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Greška prilikom otkazivanja tendera.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}
  

Widget _buildStatusBadge(TenderStatus status) {
  final label = _localStatusLabel(status);

  Color bgColor;
  Color fgColor;

  switch (status) {
   
    case TenderStatus.open:
      bgColor = Colors.green.shade100;
      fgColor = Colors.green.shade800;
      break;

    case TenderStatus.closed:
      bgColor = Colors.orange.shade100;
      fgColor = Colors.orange.shade800;
      break;

    case TenderStatus.awarded:
      bgColor = Colors.blue.shade100;
      fgColor = Colors.blue.shade800;
      break;

    case TenderStatus.cancelled:
      bgColor = Colors.red.shade100;
      fgColor = Colors.red.shade800;
      break;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: fgColor,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

  String _localStatusLabel(TenderStatus status) {
    switch (status) {
      case TenderStatus.open:
        return 'Aktivan';
      case TenderStatus.closed:
        return 'Zatvoren';
      case TenderStatus.awarded:
        return 'Dodijeljen';
      case TenderStatus.cancelled:
        return 'Otkazan';
    }
  }

  String _formatCurrency(double value) {
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String Function(Match) matchFunc = (Match match) => '${match[1]},';
    return '${value.toStringAsFixed(0).replaceAllMapped(reg, matchFunc)} KM';
  }

  @override
Widget build(BuildContext context) {
  // Izračunavanje ukupnog broja stranica za prikaz u traci
  final int totalPages = (_totalCount / _pageSize).ceil();
  final int displayTotalPages = totalPages == 0 ? 1 : totalPages;

  return Container(
    color: const Color(0xFFF8FAFC),
    width: double.infinity,
    padding: const EdgeInsets.all(32.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Naslov i Login informacije
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upravljanje tenderima',
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

        // Search polje
        Row(
          children: [
            Container(
              width: 320,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Pretraži tendere po nazivu ',
                  hintStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: InputBorder.none,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 16,
                            color: Color(0xFF94A3B8),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Tabela i Paginacija upakovane zajedno
        Expanded(
          child: _loading
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
                            color: Colors.black.withOpacity(0.015),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          // Tabela unutar svog Expanded-a kako ne bi progutala prostor paginacije
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: SizedBox(
                                width: double.infinity,
                                child: DataTable(
                                  horizontalMargin: 24,
                                  headingRowHeight: 55,
                                  dataRowMaxHeight: 80,
                                  dataRowMinHeight: 70,
                                  headingRowColor: MaterialStateProperty.all(
                                    const Color(0xFFF8FAFC),
                                  ),
                                  columns: const [
                                    DataColumn(
                                      label: Text(
                                        'Naziv tendera',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF64748B),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Raspisivač (Klijent)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF64748B),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Vrijednost (KM)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF64748B),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Rok za prijavu',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF64748B),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Status',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF64748B),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Akcije',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF64748B),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                  // Mapiranje iz serverske liste _tenders (AdminTenderDto)
                                  rows: _tenders.map((tender) {
                                    return DataRow(
                                      cells: [
                                        // Naziv tendera
                                        DataCell(
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  tender.title,
                                                  style: const TextStyle(
                                                    color: Color(0xFF1E293B),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Raspisivač
                                        DataCell(
                                          Text(
                                            tender.createdByUserFullName,
                                            style: const TextStyle(color: Color(0xFF475569)),
                                          ),
                                        ),
                                        // Vrijednost (KM)
                                        DataCell(
                                          Text(
                                            _formatCurrency(tender.maxBudget),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                        ),
                                        // Rok za prijavu
                                        DataCell(
                                          Text(
                                            DateFormat('dd.MM.yyyy.').format(tender.deadline),
                                            style: const TextStyle(color: Color(0xFF475569)),
                                          ),
                                        ),
                                        // Status
                                        DataCell(_buildStatusBadge(tender.status)),
                                        // Akcije
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              OutlinedButton(
                                                onPressed: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) => AdminTenderDetailsScreen(
                                                        tenderId: tender.id,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                style: OutlinedButton.styleFrom(
                                                  minimumSize: const Size(75, 32),
                                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'Pregledaj',
                                                  style: TextStyle(
                                                    color: Color(0xFF475569),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              if (tender.status == TenderStatus.open) ...[
                                                const SizedBox(width: 8),
                                                OutlinedButton(
                                                  onPressed: tender.status == TenderStatus.cancelled
                                                      ? null
                                                      : () {
                                                          _showCancelDialog(context, tender);
                                                        },
                                                  style: OutlinedButton.styleFrom(
                                                    minimumSize: const Size(90, 32),
                                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                                    side: BorderSide(
                                                      color: tender.status == TenderStatus.cancelled
                                                          ? const Color(0xFFFEE2E2)
                                                          : const Color(0xFFFCA5A5),
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    backgroundColor: tender.status == TenderStatus.cancelled
                                                        ? const Color(0xFFFEF2F2).withOpacity(0.4)
                                                        : null,
                                                  ),
                                                  child: Text(
                                                    tender.status == TenderStatus.cancelled
                                                        ? 'Otkazan'
                                                        : 'Otkaži (Spam)',
                                                    style: TextStyle(
                                                      color: tender.status == TenderStatus.cancelled
                                                          ? const Color(0xFFFCA5A5)
                                                          : const Color(0xFFEF4444),
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                          
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),

                       const Divider(height: 1, color: Color(0xFFE2E8F0)),

Padding(
  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
          // Prethodna stranica dugme (Outlined sa tvojim stilom)
          OutlinedButton(
           onPressed: _currentPage > 1 && !_loading
              ? _previousPage
              : null,

            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Icon(Icons.arrow_back_ios, size: 14, color: Color(0xFF475569)),
          ),
          const SizedBox(width: 8),
          
          Text(
            'Stranica $_currentPage od ${(_totalCount / _pageSize).ceil() == 0 ? 1 : (_totalCount / _pageSize).ceil()}',
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          
         OutlinedButton(
  onPressed: _currentPage < (_totalCount / _pageSize).ceil() && !_loading
      ? _nextPage
      : null,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
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
