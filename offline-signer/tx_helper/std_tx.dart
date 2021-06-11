import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:offline_tool/services/auth_info.dart';
import 'package:offline_tool/tx_helper/std_msg.dart';


class StdTx {
  final StdMsg stdMsg;
  final AuthInfo authInfo;
  final List<String> signatures;
  String accountNumber;
  String sequence;

  StdTx({
    @required this.stdMsg,
    @required this.authInfo,
    @required this.signatures,
    this.accountNumber,
    this.sequence,
  })  : assert(stdMsg != null),
        assert(authInfo != null),
        assert(signatures == null || signatures.isNotEmpty);

  Map<String, dynamic> toJson() => {
        'body': this.stdMsg.toJson(),
        'auth_info': this.authInfo.toJson(),
        'signatures': this.signatures != null ? this.signatures : [],
      };

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
