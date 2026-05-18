import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tendergo/shared/core/network/constants/category_api_endpoints.dart';
import 'package:tendergo/shared/models/dto/category_dto.dart';
import 'package:tendergo/shared/services/base_service.dart';

class CategoryService extends BaseService<CategoryDto> {


  CategoryService(Dio dio) : super(dio, CategoryApiEndpoints.baseUrl, CategoryDto.fromJson);

  
}
