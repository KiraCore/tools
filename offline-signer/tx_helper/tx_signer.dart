import 'dart:convert';

import 'package:offline_tool/models/account.dart';
import 'package:offline_tool/models/cosmos_account.dart';
import 'package:offline_tool/tx_helper/msg_send.dart';
import 'package:offline_tool/tx_helper/std_fee.dart';
import 'package:offline_tool/tx_helper/std_public_key.dart';
import 'package:offline_tool/tx_helper/std_signature_message.dart';
import 'package:offline_tool/tx_helper/std_tx.dart';
import 'package:offline_tool/utils/map_sorter.dart';

import 'package:offline_tool/services/node_info.dart';
import 'package:offline_tool/services/query_service.dart';
import 'package:offline_tool/services/signer_info.dart';
import 'package:offline_tool/services/status_service.dart';

class TransactionSigner {
  /// Signs the given [stdTx] using the info contained inside the
  /// given [wallet] and returns a new [StdTx] containing the signatures
  /// inside it.
  static Future<StdTx> signStdTx(Account account, StdTx stdTx, {String accountNumber = '', String sequence = ''}) async {
    // Get the account data and node info from the network
    if (accountNumber.isEmpty) {
      final CosmosAccount cosmosAccount = await QueryService.getAccountData(account);
      accountNumber = cosmosAccount.accountNumber;
      if (sequence.isEmpty) {
        sequence = cosmosAccount.sequence;
      }
    }

    StatusService service = StatusService();
    await service.getNodeStatus();

    // Sign all messages
    final signature = _getStdSignature(
      account,
      accountNumber,
      sequence,
      service.nodeInfo,
      stdTx.stdMsg.messages,
      stdTx.authInfo.stdFee,
      stdTx.stdMsg.memo,
    );

    Single single = Single(mode: "SIGN_MODE_LEGACY_AMINO_JSON");
    ModeInfo modeInfo = ModeInfo(single: single);

    SignerInfo signerInfo = SignerInfo(publicKey: signature['publicKey'], modeInfo: modeInfo, sequence: sequence);

    stdTx.authInfo.signerInfos = [
      signerInfo
    ];

    // Assemble the transaction
    return StdTx(
        stdMsg: stdTx.stdMsg,
        authInfo: stdTx.authInfo,
        signatures: [
          signature['signature']
        ],
        accountNumber: accountNumber,
        sequence: sequence);
  }

  static Map<String, dynamic> _getStdSignature(
    Account account,
    String accountNumber,
    String sequence,
    NodeInfo nodeInfo,
    List<MsgSend> messages,
    StdFee fee,
    String memo,
  ) {
    // Create the signature object
    final signature = StdSignatureMessage(
      sequence: sequence, //checked
      accountNumber: accountNumber, //checked
      chainId: nodeInfo.network, //checked
      fee: fee, //checked
      msgs: messages,
      memo: memo,
    );

    // Convert the signature to a JSON and sort it
    final jsonSignature = signature.toJson();
    final sortedJson = MapSorter.sort(jsonSignature);

    // Encode the sorted JSON to a string and get the bytes
    var bodyData = json.encode(sortedJson);
    final bytes = utf8.encode(bodyData);

    // Sign the data
    final signatureData = account.signTxData(bytes);

    // Get the compressed Base64 public key
    final pubKeyCompressed = account.ecPublicKey.Q.getEncoded(true);

    // Build the StdSignature
    return {
      'signature': base64Encode(signatureData),
      'publicKey': StdPublicKey(type: '/cosmos.crypto.secp256k1.PubKey', key: base64Encode(pubKeyCompressed)),
    };
  }
}
