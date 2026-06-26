import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/admin/screens/admin_tender_details_screen.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/enums/tenderstatus.dart';
import 'package:tendergo/shared/providers/admin_provider.dart';
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

  List<TenderDto> _allTenders = [];
  List<TenderDto> _filteredTenders = [];

  @override
  void initState() {
    super.initState();
    _loadTenders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTenders() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      final tenders = await adminProvider.getAllTenders();

      setState(() {
        _allTenders = tenders;
        _filteredTenders = List.from(tenders);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _filterTenders(String query) {
    final q = query.trim().toLowerCase();

    setState(() {
      if (q.isEmpty) {
        _filteredTenders = List.from(_allTenders);
      } else {
        _filteredTenders = _allTenders.where((tender) {
          final title = tender.title.toLowerCase();
          final publisher = tender.createdByFullname.toLowerCase();
          final id = tender.id.toString();
          return title.contains(q) || publisher.contains(q) || id.contains(q);
        }).toList();
      }
    });
  }

  // Funkcija koja koristi tvoj prilagođeni AppDialogs za potvrdu
  Future<void> _showCancelDialog(BuildContext context, TenderDto tender) async {
    // Pozivamo tvoj statički metod iz AppDialogs klase
    final bool confirm = await AppDialogs.showConfirm(
      context: context,
      title: 'Potvrda otkazivanja',
      content: 'Da li ste sigurni da želite otkazati tender pod nazivom "${tender.title}" (ID #${tender.id}) i označiti ga kao spam?',
      cancelLabel: 'Odustani',
      confirmLabel: 'Otkaži tender',
      isDestructive: true, // Ovo će obojiti dugme u crveno i podebljati ga
    );

    // Ako je korisnik potvrdio otkazivanje (vraćeno true)
    if (confirm && mounted) {
      setState(() => _loading = true);
      try {
        final adminProvider = Provider.of<AdminProvider>(context, listen: false);
        
        // Pozivamo metodu iz provajdera
        final updatedTender = await adminProvider.cancelTender(tender.id);

        if (updatedTender != null && updatedTender.status == TenderStatus.cancelled && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tender uspješno otkazan.')),
      );

          _loadTenders();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Greška prilikom otkazivanja tendera.')),
          );
          setState(() => _loading = false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Greška: ${e.toString()}')),
          );
          setState(() => _loading = false);
        }
      }
    }
  }
  

  // Helper metoda za generisanje stilova statusnih badge-ova
  Widget _buildStatusBadge(TenderStatus status) {
    final label = _localStatusLabel(status);
    final bgColor = status.badgeBg;
    final fgColor = status.badgeFg;

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

  // Formatiranje cifre u format sa zarezom (npr. 45,000 KM)
  String _formatCurrency(double value) {
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String Function(Match) matchFunc = (Match match) => '${match[1]},';
    return '${value.toStringAsFixed(0).replaceAllMapped(reg, matchFunc)} KM';
  }

  @override
  Widget build(BuildContext context) {
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
                  onChanged: _filterTenders,
                  decoration: InputDecoration(
                    hintText: 'Pretraži tendere po nazivu ili šifri...',
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
                              _filterTenders('');
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tabela
          Expanded(
            child: Container(
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
              child: SingleChildScrollView(
                child: DataTable(
                  horizontalMargin: 24,
                  headingRowHeight: 55,
                  dataRowMaxHeight:
                      80, 
                  dataRowMinHeight: 70,
                  headingRowColor: MaterialStateProperty.all(
                    const Color(0xFFF8FAFC),
                  ),
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Šifra i naziv tendera',
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
                  rows: _filteredTenders.map((tender) {
                    final canCancel=tender.status==TenderStatus.open;

                    return DataRow(
                      cells: [
                        // Šifra i naziv tendera
                        DataCell(
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'ID #${tender.id}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tender.title,
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Raspisivač
                        DataCell(
                          Text(
                            tender.createdByFullname,
                            style: const TextStyle(color: Color(0xFF475569)),
                          ),
                        ),
                        // Vrijednost (KM) - Boldirana
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
                       // Akcije
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
                tender: tender,
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

  
      if (tender.status == TenderStatus.open ||
          tender.status == TenderStatus.cancelled) ...[
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
        ],
      ),
    );
  }
}
