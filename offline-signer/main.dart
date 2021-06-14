import 'package:offline_tool/models/account.dart';
import 'package:offline_tool/tx_helper/msg_send.dart';
import 'package:offline_tool/tx_helper/std_coin.dart';
import 'package:offline_tool/tx_helper/std_fee.dart';
import 'package:offline_tool/tx_helper/tx_builder.dart';
import 'package:offline_tool/tx_helper/tx_sender.dart';
import 'package:offline_tool/tx_helper/tx_signer.dart';
import 'services/network_info.dart';

class Constants {
  static const String rpcUrl = "162.55.7.49";
}

Future<void> main() async {
  //  Creating an HD Wallet.
  Account currentAccount = generateAccount();

  // Creating a transaction.`
  final message = MsgSend(fromAddress: currentAccount.bech32Address, toAddress: "kira16wwvl5z97rxr3ckhmm3ca0nqku56eufa8sxyyf", amount: [
    StdCoin(denom: "ukex", amount: "109")
  ]);

  final feeV = StdCoin(amount: '100', denom: 'ukex');
  final fee = StdFee(gas: '200000', amount: [
    feeV
  ]);

  // Structure and organize the transcation
  final stdTx = TransactionBuilder.buildStdTx([
    message
  ], stdFee: fee, memo: "memo data");

  final signedStdTx = await TransactionSigner.signStdTx(currentAccount, stdTx);

  //  broadcasting the transaction
  var result = await TransactionSender.broadcastStdTx(account: currentAccount, stdTx: signedStdTx);
  print(result);
}

Account generateAccount() {
  //String mnemonicString = bip39.generateMnemonic(strength: 256);
  String mnemonicString = "hawk bulk reunion rally cancel beach argue boil minor tackle found aerobic glad mandate work club oval soccer electric marine sand rescue bleak monster";
  //  e.g. hawk bulk reunion rally cancel beach argue boil minor tackle found aerobic glad mandate work club oval soccer electric marine sand rescue bleak monster";

  List<String> mnemonic = mnemonicString.split(" ");

  final networkInfo = NetworkInfo(bech32Hrp: 'kira', lcdUrl: 'https://cors-anywhere.kira.network/http://${Constants.rpcUrl}:11000/api/cosmos');

  print(networkInfo.lcdUrl);
  // http:/${Constants.rpcUrl}:11000/api/cosmos/auth/accounts/$kiraAddress

  // Create an account from mnemonic, networkInfo and derivation path
  Account account = Account.derive(mnemonic, networkInfo);

  // Creating an account with different derivationPath
  //  const derivationPathIndex = '0'; // default 0, can be set to 1
  //  account = Account.derive(mnemonic, networkInfo, lastDerivationPathSegment: derivationPathIndex);
  return account;
}
