# Interacting with KIRA Network via RPC
**Warning:** this is experiemental, and may change over time. 



### 1-  Generating a KIRA account

Setup network RPC

    static const String rpcUrl ="162.55.7.49";

Setting up network and mnemonic    

    final networkInfo =  NetworkInfo(bech32Hrp:'kira', lcdUrl:'https://cors-anywhere.kira.network/http://${Constants.rpcUrl}:11000/api/cosmos');
    String mnemonicString =  "hawk bulk reunion rally cancel beach argue boil minor tackle found aerobic glad mandate work club oval soccer electric marine sand rescue bleak monster";
    
    // To automatically generate memonetic phrases
    //	String mnemonicString = bip39.generateMnemonic(strength: 256);
    
Create an Account (wallet) object from mnmonic and network information

    Account account = Account.derive(mnemonic, networkInfo);
  

### 2-  Creating and broadcasting transcation

Create the transcation body and include token used and fee

    final message =  MsgSend(fromAddress:currentAccount.bech32Address,toAddress:  "kira16wwvl5z97rxr3ckhmm3ca0nqku56eufa8sxyyf",amount:[StdCoin(denom:"ukex",amount:"109")]);
    
    final feeV =StdCoin(amount:'100',denom:'ukex');
    final fee =StdFee(gas:'200000', amount: [feeV]);

Structure and organize the transcation

    final stdTx =  TransactionBuilder.buildStdTx([message],stdFee:fee,memo:"memo data");

Signing the transcation 

    final signedStdTx =  await  TransactionSigner.signStdTx(currentAccount, stdTx);

Broadcasting the transaction

    var result =  await TransactionSender.broadcastStdTx(account:currentAccount,stdTx:signedStdTx);
    print(result);
