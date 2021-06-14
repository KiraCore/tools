import 'package:meta/meta.dart';
import 'package:offline_tool/tx_helper/msg_send.dart';

import 'package:offline_tool/tx_helper/std_fee.dart';

part 'std_signature_message.g.dart';

class StdSignatureMessage {
  final String accountNumber;
  final String chainId;
  final String sequence;
  final String memo;
  final StdFee fee;
  final List<MsgSend> msgs;

  const StdSignatureMessage({
    @required this.chainId,
    @required this.accountNumber,
    @required this.sequence,
    @required this.memo,
    @required this.fee,
    @required this.msgs,
  })  : assert(chainId != null),
        assert(accountNumber != null),
        assert(sequence != null),
        assert(msgs != null);

  factory StdSignatureMessage.fromJson(Map<String, dynamic> json) {
    return _$StdSignatureMessageFromJson(json);
  }

  Map<String, dynamic> toJson() {
    return _$StdSignatureMessageToJson(this);
  }
}
