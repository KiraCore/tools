import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:offline_tool/models/account.dart';
import 'package:offline_tool/models/cosmos_account.dart';
import 'package:offline_tool/services/config.dart';

class QueryService {
  static Future<CosmosAccount> getAccountData(Account account) async {
    var apiUrl = await loadInterxURL();
    final endpoint = apiUrl[0] + "/cosmos/auth/accounts/${account.bech32Address}";
    var response = await http.get(endpoint, headers: {
      'Access-Control-Allow-Origin': apiUrl[1]
    });

    if (response.statusCode != 200) {
      throw Exception(
        "Expected status code 200 but got ${response.statusCode} - ${response.body}",
      );
    }

    var data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data.containsKey("account")) {
      data = data["account"];
    }

    return CosmosAccount.fromJson(data);
  }
}
