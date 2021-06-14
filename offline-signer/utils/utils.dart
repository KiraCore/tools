

String getIPOnly(String address) {
  String rpcUrl = address;

  rpcUrl = rpcUrl.replaceAll('https://cors-anywhere.kira.network/', '');
  rpcUrl = rpcUrl.replaceAll('http://', '');
  rpcUrl = rpcUrl.replaceAll('https://', '');
  rpcUrl = rpcUrl.replaceAll('/api', '');

  List<String> urlArray = rpcUrl.split(':');
  return urlArray[0];
}
