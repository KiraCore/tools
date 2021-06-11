import 'package:offline_tool/services/auth_info.dart';
import 'package:offline_tool/tx_helper/msg_send.dart';
import 'package:offline_tool/tx_helper/std_fee.dart';
import 'package:offline_tool/tx_helper/std_msg.dart';
import 'package:offline_tool/tx_helper/std_tx.dart';

/// Allows to easily build and sign a [StdTx] that can later be sent over
/// the network.
class TransactionBuilder {
  /// Builds a [StdTx] object containing the given [stdMsgs] and having the
  /// optional [memo] and [fee] specified.
  static StdTx buildStdTx(
    List<MsgSend> messages, {
    String memo = '',
    String timeoutHeight = '0',
    StdFee stdFee,
  }) {
    // Validate the messages
    messages.forEach((msg) {
      final error = msg.validate();
      if (error != null) {
        throw error;
      }
    });

    final stdMsg = StdMsg(messages: messages, memo: memo, timeoutHeight: timeoutHeight, extensionOptions: [], nonCriticalExtensionOptions: []);

    final authInfo = AuthInfo(stdFee: stdFee, signerInfos: []);

    return StdTx(
      stdMsg: stdMsg,
      authInfo: authInfo,
      signatures: null,
    );
  }
}
