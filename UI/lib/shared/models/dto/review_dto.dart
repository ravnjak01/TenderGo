class ReviewDto {
  final int id;
  final int rating;
  final String? comment; // Nullable jer korisnik ne mora ostaviti komentar
  final DateTime createdAt;
  final String reviewerName;
  final int tenderId;
  final String tenderTitle;

  ReviewDto({
    required this.id,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.reviewerName,
    required this.tenderId,
    required this.tenderTitle,
  });

  // Fabrički konstruktor za mapiranje iz JSON formata koji stiže sa backenda
  factory ReviewDto.fromJson(Map<String, dynamic> json) {
    return ReviewDto(
       id: json['id'] as int? ?? 0,
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String?,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : DateTime.now(),
      reviewerName: json['reviewerName'] as String? ?? 'Anonimni korisnik',
      tenderId: json['tenderId'] as int? ?? 0,
      tenderTitle: json['tenderTitle'] as String? ?? 'Nepoznat tender',
    );
  }

  // (Opcionalno) Ako ti ikada zatreba da ponovo pretvoriš objekat u JSON
  Map<String, dynamic> toJson() {
    return {
      'id':id,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'reviewerName': reviewerName,
      'tenderId': tenderId,
      'tenderTitle': tenderTitle,
    };
  }
}