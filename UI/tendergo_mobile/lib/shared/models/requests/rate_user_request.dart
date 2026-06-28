
class RateUserRequest {
  final String ratedByUserId;
  final String ratedUserId;
  final int tenderId;
  final int score;
  final String? comment;

  const RateUserRequest({
    required this.ratedByUserId,
    required this.ratedUserId,
    required this.tenderId,
    required this.score,
    this.comment,
  });

  Map<String, dynamic> toJson() => {
        'ratedByUserId': ratedByUserId,
        'ratedUserId': ratedUserId,
        'tenderId': tenderId,
        'score': score,
        'comment': comment,
       
      };
}