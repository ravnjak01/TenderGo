
/** Base provider for handling API requests 
import 'dart:convert';

import 'package:flutter/material.dart';

abstract class BaseProvider<T> with ChangeNotifier{

  static String? _baseUrl;
  String _endpoint = "";

  BaseProvider(String endpoint){
    _endpoint= endpoint;
    _baseUrl=const String.fromEnvironment("baseUrl",defaultValue: "https://localhost:7209/");
  }

  Future<SearchResult<T>> get({dynamic filter}) async {
    var url="$_baseUrl$_endpoint";

    if(filter!=null)
    {
     var queryString = getQueryString(filter);
     url="$url?$queryString";

    }
    var uri=Uri.parse(url);
    var hearders=createHeaders();

    var response=await http.get(uri,headers: hearders);

    if(isValidResponse(response))
    {
      var data=jsonDecode(response.body);

      var result=SearchResult
    }
    return SearchResult<T>(data: []);
  }
}

*/