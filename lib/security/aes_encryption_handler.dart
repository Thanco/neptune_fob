// Copyright Terry Hancock 2023
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cryptography/cryptography.dart';

class AESEncryptionHandler {
  late Uint8List _aesKey;

  void storeAESKey(String aesKeyBase64) {
    _aesKey = base64.decode(aesKeyBase64);
  }

  // Uint8List _generateNonce() {
  //   final keyGenerator = Random.secure();
  //   final seed = Uint8List.fromList(List.generate(32, (n) => keyGenerator.nextInt(255)));
  //   SecureRandom sec = SecureRandom("Fortuna")..seed(KeyParameter(seed));
  //   return sec.nextBytes(12);
  // }

  Future<List<String>> encryptData(String plaintext) {
    // if (!(kIsWeb || Platform.isAndroid)) {
    // return compute<String, String>(_aesEncrypt, plaintext);
    // }
    if (plaintext.runes.toList().reduce((value, element) => value > element ? value : element) > 256) {
      return compute<String, List<String>>(_aesFastEncrypt16, plaintext);
    }
    return compute<String, List<String>>(_aesFastEncrypt, plaintext);
  }

  Future<List<String>> _aesFastEncrypt(String plaintext) async {
    final algorithm = AesGcm.with256bits(nonceLength: 12);

    final secretKey = await algorithm.newSecretKeyFromBytes(_aesKey);

    final nonce = algorithm.newNonce();

    Uint8List plaintextUint8 = Uint8List(plaintext.length);
    for (var i = 0; i < plaintext.length; i++) {
      plaintextUint8[i] = plaintext.codeUnitAt(i);
    }

    final secretBox = await algorithm.encrypt(
      plaintextUint8,
      secretKey: secretKey,
      nonce: nonce,
    );

    return [
      '"${base64.encode(secretBox.nonce)}%${base64.encode(secretBox.cipherText)}%${base64.encode(secretBox.mac.bytes)}"',
      '"8"'
    ];
  }

  Future<List<String>> _aesFastEncrypt16(String plaintext) async {
    final algorithm = AesGcm.with256bits(nonceLength: 12);

    final secretKey = await algorithm.newSecretKeyFromBytes(_aesKey);

    final nonce = algorithm.newNonce();

    List<int> plaintextUint16 = plaintext.runes.toList();
    Uint8List plaintextUint8 = Uint8List(plaintextUint16.length * 2);

    for (var i = 0; i < plaintextUint16.length; i++) {
      if (plaintextUint16[i] > 256) {
        String binary = plaintextUint16[i].toRadixString(2);
        binary = binary.padLeft(16, '0');
        plaintextUint8[i * 2] = int.parse(binary.substring(0, 8), radix: 2);
        plaintextUint8[i * 2 + 1] = int.parse(binary.substring(8), radix: 2);
      } else {
        plaintextUint8[i * 2] = 0;
        plaintextUint8[i * 2 + 1] = plaintextUint16[i];
      }
    }

    final secretBox = await algorithm.encrypt(
      plaintextUint8,
      secretKey: secretKey,
      nonce: nonce,
    );

    return [
      '"${base64.encode(secretBox.nonce)}%${base64.encode(secretBox.cipherText)}%${base64.encode(secretBox.mac.bytes)}"',
      '"16"'
    ];
  }

  // String _aesEncrypt(String plaintext) {
  //   // var plaintextUint8 = createUint8ListFromString(plaintext);
  //   Uint8List plaintextUint8 = Uint8List(plaintext.length);
  //   for (var i = 0; i < plaintext.length; i++) {
  //     plaintextUint8[i] = plaintext.codeUnitAt(i);
  //   }
  //
  //   final Uint8List nonce = generateNonce();
  //
  //   final GCMBlockCipher cipher = GCMBlockCipher(AESEngine());
  //   AEADParameters<KeyParameter> aeadParameters = AEADParameters(KeyParameter(_aesKey), 128, nonce, Uint8List(0));
  //   cipher.init(true, aeadParameters);
  //
  //   Uint8List ciphertextWithTag = cipher.process(plaintextUint8);
  //   var ciphertextWithTagLength = ciphertextWithTag.lengthInBytes;
  //   var ciphertextLength = ciphertextWithTagLength - 16; // 16 bytes = 128 bit tag length
  //   var ciphertext = Uint8List.sublistView(ciphertextWithTag, 0, ciphertextLength);
  //   var gcmTag = Uint8List.sublistView(ciphertextWithTag, ciphertextLength, ciphertextWithTagLength);
  //   final nonceBase64 = base64.encode(nonce);
  //   final ciphertextBase64 = base64.encode(ciphertext);
  //   final gcmTagBase64 = base64.encode(gcmTag);
  //   return '$nonceBase64%$ciphertextBase64%$gcmTagBase64';
  // }

  Future<String> decryptData(String encryptedBase64, String bit16) {
    // if (!(kIsWeb || Platform.isAndroid)) {
    //   return compute<String, String>(_aesDecrypt, encryptedBase64);
    // }
    if (bit16 == '16') {
      return compute<String, String>(_aesFastDecrypt16, encryptedBase64);
    }
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
    return String.fromCharCodes(textBytes);
  }

  Future<String> _aesFastDecrypt16(String encryptedBase64) async {
    var split = encryptedBase64.split('%');
    var nonce = base64.decode(split[0]);
    var ciphertext = base64.decode(split[1]);
    var gcmTag = base64.decode(split[2]);

    final algo = AesGcm.with256bits();
    final key = await algo.newSecretKeyFromBytes(_aesKey);
    SecretBox box = SecretBox(ciphertext, nonce: nonce, mac: Mac(gcmTag));
    List<int> textBytes = await algo.decrypt(box, secretKey: key);
    Uint16List u16 = Uint16List(textBytes.length ~/ 2);
    for (var i = 0; i < u16.length; i++) {
      u16[i] = int.parse(textBytes[i * 2 + 1].toRadixString(2) + textBytes[i * 2].toRadixString(2).padLeft(8, '0'),
          radix: 2);
    }
    return String.fromCharCodes(u16);
  }

  // String _aesDecrypt(String encryptedBase64) {
  //   var split = encryptedBase64.split('%');
  //   var nonce = base64.decode(split[0]);
  //   var ciphertext = base64.decode(split[1]);
  //   var gcmTag = base64.decode(split[2]);
  //
  //   var bb = BytesBuilder();
  //   bb.add(ciphertext);
  //   bb.add(gcmTag);
  //
  //   var ciphertextWithTag = bb.toBytes();
  //
  //   final cipher = GCMBlockCipher(AESEngine());
  //   var aeadParameters = AEADParameters(KeyParameter(_aesKey), 128, nonce, Uint8List(0));
  //   cipher.init(false, aeadParameters);
  //
  //   return String.fromCharCodes(cipher.process(ciphertextWithTag));
  // }
}
