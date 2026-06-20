import 'package:tendergo/shared/models/requests/paged_search_request.dart';

class LocationSearchRequest extends PagedSearchRequest {
  final String? searchTerm;
  final bool? isActive;
  final String? country;

  LocationSearchRequest({this.searchTerm, this.isActive, this.country}) : super(page: 1, pageSize: 10);
}