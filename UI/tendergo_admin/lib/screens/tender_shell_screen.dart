import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo_admin/providers/tender_provider.dart';
import 'package:tendergo_admin/screens/tender_details_screen.dart';
import 'package:tendergo_admin/screens/tender_post_screen.dart';
import 'package:tendergo_admin/screens/tenders_list_screen.dart';
import 'package:tendergo_admin/services/tender_service.dart';

class TenderShellScreen extends StatefulWidget {
  final TenderService tenderService;

  const TenderShellScreen({
    super.key,
    required this.tenderService,
  });

  @override
  State<TenderShellScreen> createState() => _TenderShellScreenState();
}

class _TenderShellScreenState extends State<TenderShellScreen> {
  int? _selectedTenderId;

  void _openTenderListFromTopBar() {
    setState(() {
      _selectedTenderId = null;
    });
  }

  Future<void> _openPostTender() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TenderPostScreen(tenderService: widget.tenderService),
      ),
    );

    if (result == true && mounted) {
      await context.read<TenderProvider>().fetchActiveTenders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            InkWell(
              onTap: _openTenderListFromTopBar,
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'TenderGo',
                  style: TextStyle(
                    color: Color(0xFF185FA5),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            TextButton.icon(
              onPressed: _openTenderListFromTopBar,
              icon: const Icon(
                Icons.home_outlined,
                size: 20,
                color: Colors.black87,
              ),
              label: const Text(
                'Home',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (_selectedTenderId != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedTenderId = null;
                  });
                },
                child: const Text('Tenders'),
              ),
            const Spacer(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: _openPostTender,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF185FA5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('+ Post a tender'),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE5E3DC),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'JD',
                      style: TextStyle(
                        color: Color(0xFF185FA5),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xFFE5E3DC)),
        ),
      ),
      body: _selectedTenderId == null
          ? TenderListScreen(
              tenderService: widget.tenderService,
              embedded: true,
              onTenderSelected: (id) {
                setState(() {
                  _selectedTenderId = id;
                });
              },
            )
          : TenderDetailsScreen(
              tenderService: widget.tenderService,
              tenderId: _selectedTenderId,
              embedded: true,
            ),
    );
  }
}
