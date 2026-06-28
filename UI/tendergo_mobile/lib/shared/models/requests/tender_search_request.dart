class TenderSearchRequest{
  final String? searchTerm;
 
  TenderSearchRequest({
   this.searchTerm,
  });

  Map<String, dynamic> toJson() => {
        if (searchTerm != null) 'searchTerm': searchTerm,
      };
}