import 'package:tendergo/shared/controllers/paginated_list_controller.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/providers/tender_provider.dart';
import 'package:tendergo/shared/services/auth_service.dart';
import 'package:tendergo/shared/services/tender_service.dart';

/// Controller for "My Tenders" list pagination
/// Note: Backend service doesn't support pagination params, so we fetch all in one call
class TendersListController extends BasePaginatedListController<TenderDto> {
  final TenderProvider tenderProvider;

  TendersListController(this.tenderProvider);

  @override
  Future<List<TenderDto>> fetchPageData(int page, {int pageSize = 10}) async {

    await tenderProvider.fetchAllTenders();
    return tenderProvider.tenders;
  }

  @override
  Future<void> _performFetch({bool refresh = false}) async {
    if (currentPage > 1) return; // Only fetch once

    if (refresh) {
      _resetPagination();
    }

    isLoading = true;
    hasError = false;
    errorMessage = '';

    try {
      final newItems = await fetchPageData(currentPage, pageSize: pageSize);
      items = newItems;
      hasMore = false; 
      currentPage++;
      onDataFetched(newItems);
    } catch (e) {
      hasError = true;
      errorMessage = e.toString();
      onFetchError(errorMessage);
    } finally {
      isLoading = false;
    }
  }

  void _resetPagination() {
    items.clear();
    currentPage = 1;
    hasMore = true;
    hasError = false;
    errorMessage = '';
  }
}
