import 'package:tendergo/shared/models/requests/paged_search_request.dart';

class TenderSearchRequest extends PagedSearchRequest {
  final int? categoryId;
  final int? locationId;
  final String? country;
  final String? region;

  TenderSearchRequest({
    this.categoryId,
    this.locationId,
    this.country,
    this.region,
    String? searchTerm,
    int page = 1,
    int pageSize = 3,
  }) : super(
          page: page,
          pageSize: pageSize,
          searchTerm: searchTerm,
        );

  @override
  Map<String, dynamic> toQueryParams() {
    final params = super.toQueryParams();

    if (categoryId != null) {
      params['CategoryId'] = categoryId;
    }
    if (locationId != null) {
      params['LocationId'] = locationId;
    }
    if (country != null && country!.isNotEmpty) {
      params['Country'] = country;
    }
    if (region != null && region!.isNotEmpty) {
      params['Region'] = region;
    }

    return params;
  }
}