// Copyright Terry Hancock 2023
import 'package:neptune_fob/security/aes_encryption_handler.dart';
import 'package:neptune_fob/security/rsa_encryption_handler.dart';

class EncryptionHandler {
  late RSAEncryptionHandler? _rsaHandler;
  late AESEncryptionHandler? _aesHandler;

  List<String> getPublicKey() {
    _aesHandler = null;
    _rsaHandler = RSAEncryptionHandler();
    return _rsaHandler!.generateRSAKeyPair();
  }

  void putSessionKey(String sessionKeyBase64) {
    _aesHandler = AESEncryptionHandler();
    String sessionKey = _rsaHandler!.decryptData(sessionKeyBase64);
    _rsaHandler = null;
    _aesHandler = AESEncryptionHandler();
    _aesHandler!.storeAESKey(sessionKey);
  }

  Future<String> encrypt(String content) => _aesHandler!.encryptData(content);
  Future<String> decrypt(String content) => _aesHandler!.decryptData(content);
}
