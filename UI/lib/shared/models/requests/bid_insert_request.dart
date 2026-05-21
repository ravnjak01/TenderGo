class BidInsertRequest {
  final double price;
  final int tenderId;
  final String? note;
	final String userId;
  final int deliveryDays;

  BidInsertRequest({
    required this.price,
    required this.tenderId,
		required this.userId,
    this.note,
    required this.deliveryDays,
  });

  Map<String, dynamic> toJson()=> {
      'price': price,
      'tenderId': tenderId,
      'note': note,
      'userId': userId,
      'deliveryDays': deliveryDays,
  };
}