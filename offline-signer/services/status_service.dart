// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:offline_tool/main.dart';
import 'package:offline_tool/services/config.dart';
import 'package:offline_tool/services/node_info.dart';
import 'package:offline_tool/services/sync_info.dart';
import 'package:offline_tool/utils/utils.dart';
import 'package:offline_tool/services/validator_info.dart';

String origin = html.window.location.host + html.window.location.pathname;

class StatusService {
  NodeInfo nodeInfo;
  SyncInfo syncInfo;
  ValidatorInfo validatorInfo;
  String interxPubKey;
  String rpcUrl = "";
  bool isNetworkHealthy = true;
//rpcUrl + '/api'
  Future<bool> getNodeStatus() async {
    var apiUrl = await loadInterxURL();
    var config = "${Constants.rpcUrl}/api";
    var response;
    rpcUrl = getIPOnly(apiUrl[0]);

    response = await http.get(apiUrl[0] + "/kira/status", headers: {
      'Access-Control-Allow-Origin': origin
    }).timeout(Duration(seconds: 3));

    if (response.body.contains('node_info') == false && config[0] == true) {
      rpcUrl = getIPOnly(config[1]);

      response = await http.get(config[1] + "/kira/status", headers: {
        'Access-Control-Allow-Origin': origin
      }).timeout(Duration(seconds: 3));

      if (response.body.contains('node_info') == false) {
        return false;
      }
    }

    var bodyData = json.decode(response.body);

    nodeInfo = NodeInfo.fromJson(bodyData['node_info']);
    syncInfo = SyncInfo.fromJson(bodyData['sync_info']);
    validatorInfo = ValidatorInfo.fromJson(bodyData['validator_info']);

    response = await http.get(apiUrl[0] + '/status', headers: {
      'Access-Control-Allow-Origin': apiUrl[1]
    });

    if (response.body.contains('interx_info') == false && config[0] == true) {
      response = await http.get(config[1] + "/status", headers: {
        'Access-Control-Allow-Origin': origin
      });
      if (response.body.contains('interx_info') == false) {
        return false;
      }
    }

    bodyData = json.decode(response.body);
    interxPubKey = bodyData['interx_info']['pub_key']['value'];

    return true;
  }
}
