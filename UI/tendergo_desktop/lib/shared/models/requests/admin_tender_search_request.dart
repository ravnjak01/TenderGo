import 'package:tendergo/shared/models/enums/tenderstatus.dart';
import 'package:tendergo/shared/models/requests/paged_search_request.dart';

class AdminTenderSearchRequest extends PagedSearchRequest {
  final String? searchTerm;
  final TenderStatus? status;

  AdminTenderSearchRequest({
    this.searchTerm,
    this.status,
    int page = 1,
    int pageSize = 3, 
  }) : super(page: page, pageSize: pageSize);

  @override
  Map<String, dynamic> toJson() {
    return {
      'Page': page,
      'PageSize': pageSize,
      if (searchTerm != null && searchTerm!.trim().isNotEmpty) 'SearchTerm': searchTerm!.trim(),
      if (status != null) 'Status': status!.index + 1,
    };
  }
}