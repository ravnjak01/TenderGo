import 'package:tendergo/shared/core/utils/json_parser.dart';

class TenderImageDto {
  final String imageUrl;
  final bool isPrimary;
  final String imageHash;
  final String fileName;
  TenderImageDto({
    required this.imageUrl,
    required this.isPrimary,
    required this.fileName,
    required this.imageHash
  });

 factory TenderImageDto.fromJson(Map<String, dynamic> json) {
    return TenderImageDto(
      imageUrl: json['imageUrl'] ?? '',
      isPrimary: json['isPrimary'] ?? false,
      imageHash: json['imageHash'] ?? '',
      fileName: json['fileName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'imageUrl': imageUrl,
        'isPrimary': isPrimary,
      };
}
