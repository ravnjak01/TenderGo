import 'package:tendergo/shared/controllers/paginated_list_controller.dart';
import 'package:tendergo/shared/models/dto/bid_dto.dart';
import 'package:tendergo/shared/services/bid_service.dart';

/// Controller for "My Bids" list pagination
class BidsListController extends BasePaginatedListController<BidDto> {
  final BidService bidService;

  BidsListController(this.bidService);

  @override
  Future<List<BidDto>> fetchPageData(int page, {int pageSize = 10}) =>
      bidService.getMyBids(page: page, pageSize: pageSize);
}
