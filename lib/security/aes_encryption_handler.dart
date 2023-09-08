// Copyright Terry Hancock 2023
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cryptography/cryptography.dart';

class AESEncryptionHandler {
  late Uint8List _aesKey;

  void storeAESKey(String aesKeyBase64) {
    _aesKey = base64.decode(aesKeyBase64);
  }

  Future<String> encryptData(String plaintext) {
    return compute<String, String>(_aesFastEncrypt, plaintext);
  }

  Future<String> _aesFastEncrypt(String plaintext) async {
    final algorithm = AesGcm.with256bits(nonceLength: 12);

    final secretKey = await algorithm.newSecretKeyFromBytes(_aesKey);

    final nonce = algorithm.newNonce();

    final plaintextUint8 = utf8.encode(plaintext);

    final secretBox = await algorithm.encrypt(
      plaintextUint8,
      secretKey: secretKey,
      nonce: nonce,
    );

    return '${base64.encode(secretBox.nonce)}%${base64.encode(secretBox.cipherText)}%${base64.encode(secretBox.mac.bytes)}';
  }

  Future<String> decryptData(String encryptedBase64) {
    return compute<String, String>(_aesFastDecrypt, encryptedBase64);
  }

  Future<String> _aesFastDecrypt(String encryptedBase64) async {
    var split = encryptedBase64.split('%');
    var nonce = base64.decode(split[0]);
    var ciphertext = base64.decode(split[1]);
    var gcmTag = base64.decode(split[2]);

    final algo = AesGcm.with256bits();
    final key = await algo.newSecretKeyFromBytes(_aesKey);
    SecretBox box = SecretBox(ciphertext, nonce: nonce, mac: Mac(gcmTag));
    final textBytes = await algo.decrypt(box, secretKey: key);
    return utf8.decode(textBytes);
  }
}
