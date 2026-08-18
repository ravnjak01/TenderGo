import 'package:tendergo/shared/models/requests/paged_search_request.dart';

class TenderSearchRequest extends PagedSearchRequest {
  final List<int>? categoryIds;
  final int? locationId;
  final String? country;
  final String? region;

  TenderSearchRequest({
    this.locationId,
    this.country,
    this.region,
    this.categoryIds,
    super.searchTerm,
    super.page,
    super.pageSize,
  });

  @override
  Map<String, dynamic> toQueryParams() {
    final params = super.toQueryParams();

   
    if (locationId != null) {
      params['LocationId'] = locationId;
    }
    if (country != null && country!.isNotEmpty) {
      params['Country'] = country;
    }
    if (region != null && region!.isNotEmpty) {
      params['Region'] = region;
    }
    if (categoryIds != null && categoryIds!.isNotEmpty) {
      params['categoryIds'] = categoryIds;
    }

    return params;
  }
}