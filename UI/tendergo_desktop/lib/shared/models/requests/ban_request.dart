class BanRequest {
  final String reason;
  
  const BanRequest({
    required this.reason,
  });

  Map<String, dynamic> toJson() =>{
    'reason': reason,
  };
}