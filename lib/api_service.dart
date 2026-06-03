
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.0.2.2/farmxchange_api/";

  static Future<String> login(String email, String password) async {
    var response = await http.get(
      Uri.parse("${baseUrl}login.php?email=$email&password=$password"),
    );

    return response.body;
  }
}