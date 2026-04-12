import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo_admin/providers/tender_provider.dart';
import 'package:tendergo_admin/services/tender_service.dart';
import 'package:tendergo_admin/widgets/tender_filter_bar.dart';
import 'package:tendergo_admin/widgets/tender_grid.dart';
import 'package:tendergo_admin/screens/tender_post_screen.dart';

class TenderListScreen extends StatefulWidget {
  final TenderService tenderService;
  final bool embedded;
  final ValueChanged<int>? onTenderSelected;

  const TenderListScreen({
    super.key,
    required this.tenderService,
    this.embedded = false,
    this.onTenderSelected,
  });

  @override
  State<TenderListScreen> createState() => _TenderListScreenState();
}

class _TenderListScreenState extends State<TenderListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<TenderProvider>();
      provider.fetchActiveTenders();
      provider.fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Container(
        color: const Color(0xFFF4F2EB),
        child: _buildBody(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EB),
      appBar: _buildAppBar(context),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          const Text(
            'TenderGo',
            style: TextStyle(
              color: Color(0xFF185FA5),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 24),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.home_outlined, size: 20, color: Colors.black87),
            label: const Text('Home', style: TextStyle(color: Colors.black87)),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TenderPostScreen(tenderService: widget.tenderService),
                ),
              );
              if (result == true && context.mounted) {
                await context.read<TenderProvider>().fetchActiveTenders();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF185FA5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: const Color(0xFFE5E3DC)),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<TenderProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(child: Text('Error: ${provider.error}'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TenderFilterBar(tenderCount: provider.filteredTenders.length),
              TenderGrid(
                tenders: provider.filteredTenders,
                tenderService: widget.tenderService,
                onTenderSelected: widget.onTenderSelected,
              ),
            ],
          ),
        );
      },
    );
  }
}