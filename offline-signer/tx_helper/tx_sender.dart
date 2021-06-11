import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:offline_tool/models/account.dart';
import 'package:offline_tool/services/config.dart';
import 'package:offline_tool/tx_helper/std_tx.dart';

class TransactionSender {
  static Future<dynamic> broadcastStdTx({
    @required Account account,
    @required StdTx stdTx,
    String mode = "block",
  }) async {
    // final apiUrl = "${account.networkInfo.lcdUrl}/txs";
    // Get the endpoint
    var apiUrl = await loadInterxURL();

    // Build the request body
    final requestBody = {
      "tx": stdTx.toJson(),
      "mode": mode
    };
    final requestBodyJson = jsonEncode(requestBody);

    // Get the response
    final response = await http.post(apiUrl[0] + '/cosmos/txs',
        headers: {
          'Access-Control-Allow-Origin': apiUrl[1]
        },
        body: requestBodyJson);

    if (response.statusCode != 200) {
      print(
        "Expected status code 200 but got ${response.statusCode} - ${response.body}",
      );
      return false;
    }

    // Convert the response
    final json = jsonDecode(response.body);

    return json;
  }
  /*
      if (response.statusCode != 200) {
      print(
        "Expected status code 200 but got ${response.statusCode} - ${response.body}",
      );
      return false;
    } else {
      if (json['height' == "0"]) {
        print("Tx send error: " + json['check_tx']['log']);
        return false;
      } else if (json['check_tx']['log'].toString().contains("invalid")) {
        print("Invalid request");
        return false;
      } else {
        print("Tx send successfully. Hash: 0x" + json['hash']);
        return true;
      }
      return false;
    }


    if (response.statusCode != 200) {
      print(
        "Expected status code 200 but got ${response.statusCode} - ${response.body}",
      );
      // throw Exception(
      //   "Expected status code 200 but got ${response.statusCode} - ${response.body}",
      // );

    } else {
      final json = jsonDecode(response.body);

      if (json['height' == "0"]) {
        print("Tx send error: " + json['check_tx']['log']);
      } else if (json['check_tx']['log'].toString().contains("invalid")) {
        print("Invalid request");
      } else {
        print("Tx send successfully. Hash: 0x" + json['hash']);
      }
    }
    return false;
  }
  */
}
