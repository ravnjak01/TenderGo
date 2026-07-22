class TenderCancelRequest{
  final String reason;
 

  TenderCancelRequest({
 required  this.reason,
  });

  Map<String, dynamic> toJson() => {
        'reason': reason,
      };
}