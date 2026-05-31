class BanRequest {
  final String reason;

  BanRequest({required this.reason});

  Map<String, dynamic> toJson() {
    return {
      'reason': reason,
    };
  }
}