import 'package:flutter/material.dart';
import 'package:tendergo/mobile/widgets/tender/tender_widget.dart';
import 'package:tendergo/shared/core/auth/auth_token_store.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/models/dto/paged_result.dart';
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
  static const AuthTokenStore _tokenStore = AuthTokenStore();

  static const int _pageSize = 2;
  PagedResult<TenderDto> _bookmarkedTenders = PagedResult(result: [], totalCount: 0, page: 1, pageSize: _pageSize);
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadMoreBookmarks() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final response = await widget.tenderService.getBookmarked(page: nextPage, pageSize: _pageSize);

      if (!mounted) return;

      setState(() {
        _currentPage = nextPage;
        _bookmarkedTenders.result.addAll(response.result);
        _hasMore = _bookmarkedTenders.result.length < response.totalCount;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }
  Future<void> _loadBookmarks() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      if (!await _tokenStore.hasValidAccessToken()) {
        if (!mounted) return;
        setState(() {
          _bookmarkedTenders = PagedResult(result: [], totalCount: 0, page: 1, pageSize: _pageSize  );
          _isLoading = false;
        });
        return;
      }

      final tenders = await widget.tenderService.getBookmarked(page: 1, pageSize: _pageSize);

      setState(() {
        _bookmarkedTenders = tenders;
        _currentPage = tenders.page;
        _hasMore = tenders.result.isNotEmpty && tenders.result.length < tenders.totalCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while loading bookmarked tenders.';
        _isLoading = false;
      });
    }
  }

  Future<void> _removeBookmark(TenderDto dto) async {
    try {
      await widget.tenderService.toggleBookmark(dto.id);
      
      
      setState(() {
        _bookmarkedTenders = _bookmarkedTenders..result.removeWhere((t) => t.id == dto.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from saved.'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
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
          'Saved tenders',
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

    if (_bookmarkedTenders.result.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border_rounded, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'You have no saved tenders.',
              style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _currentPage = 1;
        _hasMore = true;
        await _loadBookmarks();
      },
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _bookmarkedTenders.result.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _bookmarkedTenders.result.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: _isLoadingMore
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loadMoreBookmarks,
                        icon: const Icon(Icons.expand_circle_down_rounded, size: 18),
                        label: const Text('Load more'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
            );
          }

          final dto = _bookmarkedTenders.result[index];
          final cardModel = TenderCardModel.fromDTO(dto);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MobileTenderCardWidget(
              tender: cardModel,
              isSaved: true,
              onTap: () => widget.onTenderSelected(dto.id),
              onSave: () => _removeBookmark(dto),
            ),
          );
        },
      ),
    );
  }
}
