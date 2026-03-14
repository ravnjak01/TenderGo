import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {

  Future<bool> login(String email, String password) async {

    final response = await http.post(
      Uri.parse("https://localhost:5001/api/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password
      }),
    );

    if(response.statusCode == 200){
      return true;
    }

    return false;
  }
}