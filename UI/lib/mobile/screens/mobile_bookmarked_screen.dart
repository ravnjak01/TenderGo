import 'package:flutter/material.dart';
import 'package:tendergo/mobile/widgets/tender_widget.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/ui/tendercardmodel.dart';
import 'package:tendergo/shared/services/tender_service.dart';

class MobileBookmarkedTendersScreen extends StatefulWidget {
  final TenderService tenderService;
  final ValueChanged<int> onTenderSelected;

  const MobileBookmarkedTendersScreen({
    super.key,
    required this.tenderService,
    required this.onTenderSelected,
  });

  @override
  State<MobileBookmarkedTendersScreen> createState() => _MobileBookmarkedTendersScreenState();
}

class _MobileBookmarkedTendersScreenState extends State<MobileBookmarkedTendersScreen> {
  List<TenderDto> _bookmarkedTenders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final tenders = await widget.tenderService.getBookmarked();

      setState(() {
        _bookmarkedTenders = tenders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Greška pri učitavanju sačuvanih tendera.';
        _isLoading = false;
      });
    }
  }

  Future<void> _removeBookmark(TenderDto dto) async {
    try {
      // Backend toggle uklanja bookmark i vraća false
      await widget.tenderService.toggleBookmark(dto.id);
      
      
      setState(() {
        _bookmarkedTenders.removeWhere((t) => t.id == dto.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uklonjeno iz sačuvanih.'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Sačuvani tenderi',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)));
    }

    if (_bookmarkedTenders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border_rounded, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nemate sačuvanih tendera.',
              style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookmarks,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _bookmarkedTenders.length,
        itemBuilder: (context, index) {
          final dto = _bookmarkedTenders[index];
          
          // Mapiranje DTO objekta u UI model kartice
          final cardModel = TenderCardModel.fromDTO(dto);

          return Padding(
            padding: const EdgeInsets.only(bottom:12),
            child: MobileTenderCardWidget(
              tender: cardModel,
              isSaved: true, // Na ovom ekranu su svi po defaultu sačuvani
              onTap: () => widget.onTenderSelected(dto.id),
              onSave: () => _removeBookmark(dto), // Klik na srce uklanja sa liste
            ),
          );
        },
      ),
    );
  }
}