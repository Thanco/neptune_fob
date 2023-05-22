import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/ecb.dart';
import 'package:pointycastle/pointycastle.dart';

class AESEncryptionHandler {
  late String _aesKey;

  void storeAESKey(String aesKeyBase64) {
    _aesKey = aesKeyBase64;
  }

  String encryptData(String plaintext) {
    final keyBytes = base64.decode(_aesKey);
    final cipher = ECBBlockCipher(AESEngine());
    cipher.init(false, PaddedBlockCipherParameters(KeyParameter(keyBytes), null));

    final paddedPlaintext = pad(plaintext);
    final ciphertext = cipher.process(paddedPlaintext);

    return base64.encode(ciphertext);
  }

  String decryptData(String encryptedBase64) {
    final keyBytes = base64.decode(_aesKey);
    final cipher = ECBBlockCipher(AESEngine());
    cipher.init(false, PaddedBlockCipherParameters(KeyParameter(keyBytes), null));

    final encryptedBytes = base64.decode(encryptedBase64);
    final paddedPlaintext = cipher.process(encryptedBytes);

    return removePadding(paddedPlaintext);
  }

  Uint8List pad(String input) {
    final paddedLength = ((input.length + 15) ~/ 16) * 16;
    final paddingLength = paddedLength - input.length;
    final padding = List.filled(paddingLength, paddingLength.toUnsigned(8));
    return Uint8List.fromList(utf8.encode(input)..addAll(padding));
  }

  String removePadding(Uint8List paddedPlaintext) {
    final paddingLength = paddedPlaintext.last;
    return utf8.decode(paddedPlaintext.sublist(0, paddedPlaintext.length - paddingLength));
  }
}
