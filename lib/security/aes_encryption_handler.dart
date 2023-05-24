import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
class AESEncryptionHandler {
  late Uint8List _aesKey;

  void storeAESKey(String aesKeyBase64) {
    _aesKey = base64.decode(aesKeyBase64);
  }

  Uint8List generateNonce() {
    final keyGenerator = Random.secure();
    final seed = Uint8List.fromList(List.generate(32, (n) => keyGenerator.nextInt(255)));
    SecureRandom sec = SecureRandom("Fortuna")..seed(KeyParameter(seed));
    return sec.nextBytes(12);
  }

  String encryptData(String plaintext) {
    // var plaintextUint8 = createUint8ListFromString(plaintext);
    Uint8List plaintextUint8 = Uint8List(plaintext.length);
    for (var i = 0; i < plaintext.length; i++) {
      plaintextUint8[i] = plaintext.codeUnitAt(i);
    }

    final Uint8List nonce = generateNonce();

    final GCMBlockCipher cipher = GCMBlockCipher(AESEngine());
    AEADParameters<KeyParameter> aeadParameters = AEADParameters(KeyParameter(_aesKey), 128, nonce, Uint8List(0));
    cipher.init(true, aeadParameters);

    Uint8List ciphertextWithTag = cipher.process(plaintextUint8);
    var ciphertextWithTagLength = ciphertextWithTag.lengthInBytes;
    var ciphertextLength = ciphertextWithTagLength - 16; // 16 bytes = 128 bit tag length
    var ciphertext = Uint8List.sublistView(ciphertextWithTag, 0, ciphertextLength);
    var gcmTag = Uint8List.sublistView(ciphertextWithTag, ciphertextLength, ciphertextWithTagLength);
    final nonceBase64 = base64.encode(nonce);
    final ciphertextBase64 = base64.encode(ciphertext);
    final gcmTagBase64 = base64.encode(gcmTag);
    return '$nonceBase64%$ciphertextBase64%$gcmTagBase64';
  }

  String decryptData(String encryptedBase64) {
    var split = encryptedBase64.split('%');
    var nonce = base64.decode(split[0]);
    var ciphertext = base64.decode(split[1]);
    var gcmTag = base64.decode(split[2]);

    var bb = BytesBuilder();
    bb.add(ciphertext);
    bb.add(gcmTag);

    var ciphertextWithTag = bb.toBytes();

    final cipher = GCMBlockCipher(AESEngine());
    var aeadParameters = AEADParameters(KeyParameter(_aesKey), 128, nonce, Uint8List(0));
    cipher.init(false, aeadParameters);

    return String.fromCharCodes(cipher.process(ciphertextWithTag));
  }
}
