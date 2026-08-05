import 'package:tendergo/shared/models/requests/paged_search_request.dart';

class TenderSearchRequest extends PagedSearchRequest {
  final int? locationId;
  final String? country;
  final String? region;
  final int? categoryId;

  TenderSearchRequest({
    this.locationId,
    this.country,
    this.region,
    this.categoryId,
    super.page = 1,
    super.pageSize = 10,
    super.searchTerm,
  });

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    
    if (locationId != null) map['locationId'] = locationId;
    if (country != null && country!.isNotEmpty) map['country'] = country;
    if (region != null && region!.isNotEmpty) map['region'] = region;
    if (categoryId != null) map['categoryId'] = categoryId;

    return map;
  }
}