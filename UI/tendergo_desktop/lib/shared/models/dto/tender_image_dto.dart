import 'package:tendergo/shared/core/utils/json_parser.dart';

class TenderImageDto {
  final String imageUrl;
  final bool isPrimary;

  TenderImageDto({
    required this.imageUrl,
    required this.isPrimary,
  });

  factory TenderImageDto.fromJson(Map<String, dynamic> json) {
    return TenderImageDto(
      imageUrl: JsonParser.readString(json['imageUrl']),
      isPrimary: JsonParser.readBool(json['isPrimary']),
    );
  }

  Map<String, dynamic> toJson() => {
        'imageUrl': imageUrl,
        'isPrimary': isPrimary,
      };
}
