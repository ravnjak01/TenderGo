class TenderImageDto {
  final String imageUrl;
  final bool isPrimary;

  TenderImageDto({
    required this.imageUrl,
    required this.isPrimary,
  });

  factory TenderImageDto.fromJson(Map<String, dynamic> json) {
    return TenderImageDto(
      imageUrl: json['imageUrl'] as String? ?? "", 
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'imageUrl': imageUrl,
        'isPrimary': isPrimary,
      };
}
