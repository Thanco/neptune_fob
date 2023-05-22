import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

class RSAEncryptionHandler {
  late RSAPrivateKey _privateKey;

  List<String> generateRSAKeyPair() {
    final keyParams = RSAKeyGeneratorParameters(BigInt.from(65537), 2048, 64);
    final secureRandom = FortunaRandom();
    final random = Random.secure();
    final seed = List<int>.generate(32, (_) => random.nextInt(256));

    secureRandom.seed(KeyParameter(Uint8List.fromList(seed)));
    final generator = RSAKeyGenerator()..init(ParametersWithRandom(keyParams, secureRandom));
    final pair = generator.generateKeyPair();

    final publicKey = pair.publicKey as RSAPublicKey;
    _privateKey = pair.privateKey as RSAPrivateKey;

    // Get the modulus and exponent of the public key
    final modulus = publicKey.modulus;
    final exponent = publicKey.exponent;

    // Convert modulus and exponent to BigInt
    final modulusBigInt = BigInt.parse(modulus.toString());
    final exponentBigInt = BigInt.parse(exponent.toString());

    // Convert BigInt values to base64-encoded strings
    final modulusBase64 = _bigIntToBase64(modulusBigInt);

    // Send modulusBase64 and exponentBase64 to the Java server
    // for RSA key pair generation on the server-side
    return [modulusBase64, exponentBigInt.toString()];
  }

  String _bigIntToBase64(BigInt bigInt) {
    final bigIntBinary = bigInt.toRadixString(2);
    List<int> list = [];
    for (var i = 0; i < bigIntBinary.length; i += 8) {
      list.add(int.parse(bigIntBinary.substring(i, i + 8), radix: 2));
    }
    return base64Encode(list);
  }

  String decryptData(String encryptedBase64) {
    // Convert the Base64-encoded string to bytes
    final encryptedBytes = base64.decode(encryptedBase64);

    // Create the RSA cipher and initialize with the private key
    final cipher = OAEPEncoding(RSAEngine())..init(false, PrivateKeyParameter<RSAPrivateKey>(_privateKey));

    // Perform the RSA decryption
    // final decryptedBytes = _processInBlocks(cipher, encryptedBytes);
    final decryptedBytes = cipher.process(encryptedBytes);

    // Convert the decrypted bytes to string
    print(decryptedBytes);
    // final decryptedText = utf8.decode((decryptedBytes));

    return String.fromCharCodes(decryptedBytes);
    // return decryptedText;
  }

  Uint8List _processInBlocks(AsymmetricBlockCipher engine, Uint8List input) {
    final numBlocks = input.length ~/ engine.inputBlockSize + ((input.length % engine.inputBlockSize != 0) ? 1 : 0);
    final output = Uint8List(numBlocks * engine.outputBlockSize);
    var inputOffset = 0;
    var outputOffset = 0;
    while (inputOffset < input.length) {
      final chunkSize =
          (inputOffset + engine.inputBlockSize <= input.length) ? engine.inputBlockSize : input.length - inputOffset;
      outputOffset += engine.processBlock(input, inputOffset, chunkSize, output, outputOffset);
      inputOffset += chunkSize;
    }
    return (output.length == outputOffset) ? output : output.sublist(0, outputOffset);
  }
}
