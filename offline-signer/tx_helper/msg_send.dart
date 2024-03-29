import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:offline_tool/tx_helper/std_coin.dart';



part 'msg_send.g.dart';

/// [MsgSend] represents the message that should be
/// used when sending tokens from one user to another one.
/// It requires to specify the address from which to send the tokens,
/// the one that should receive the tokens and the amount of tokens
/// to send.
@JsonSerializable(explicitToJson: true)
class MsgSend {
  /// Bech32 address of the sender.
  @JsonKey(name: 'from_address')
  final String fromAddress;

  /// Bech32 address of the recipient.
  @JsonKey(name: 'to_address')
  final String toAddress;

  /// Coins that will be sent.
  @JsonKey(name: 'amount')
  final List<StdCoin> amount;

  /// Public constructor.
  MsgSend({
    @required this.fromAddress,
    @required this.toAddress,
    @required this.amount,
  });

  factory MsgSend.fromJson(Map<String, dynamic> json) {
    return _$MsgSendFromJson(json);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> response = {
      '@type': "/cosmos.bank.v1beta1.MsgSend"
    };
    response.addAll(_$MsgSendToJson(this));
    return response;
  }

  Map<String, dynamic> toEncodeJson() {
    Map<String, dynamic> response = {
      'type': "cosmos-sdk/MsgSend",
      'value': _$MsgSendToJson(this)
    };
    return response;
  }

  Exception validate() {
    if (fromAddress.isEmpty || toAddress.isEmpty) {
      return Exception('from_address and to_address cannot be empty');
    }

    if (amount.isEmpty) {
      return Exception('amount cannot be empty');
    }

    return null;
  }
}
