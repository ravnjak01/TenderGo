class BidInsertRequest {
  final double price;
  final int tenderId;
  final String? note;
	final String userId;

  BidInsertRequest({
    required this.price,
    required this.tenderId,
		required this.userId,
    this.note,
  });

  Map<String, dynamic> toJson()=> {
      'price': price,
      'tenderId': tenderId,
      'note': note,
      'userId': userId,
  };
}