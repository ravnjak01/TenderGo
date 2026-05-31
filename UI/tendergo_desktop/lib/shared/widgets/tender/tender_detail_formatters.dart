import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/services/dio_client.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String formatTenderDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';

String formatTenderBudget(double value) =>
    '${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} KM';

List<String> extractTenderImageUrls(TenderDto tender) {
  return tender.images
      .map((img) => DioClient.resolveImageUrl(img.imageUrl.trim()))
      .whereType<String>()
      .where((url) => url.isNotEmpty)
      .toList();
}
