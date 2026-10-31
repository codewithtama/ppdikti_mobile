import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';

/// Utilitas kriptografi PDDikti Kemdiktisaintek.
/// Upstream PDDikti menggunakan enkripsi AES-256-CBC dengan PKCS7 padding
/// untuk payload pencarian terpadu (`/api/pencarian/enc/all/...`) dan ID entitas.
class PddiktiCrypto {
  PddiktiCrypto._();

  static final Uint8List _keyBytes = base64Decode('ecHyOABV9jgO2/+dzE49cfexQpr/H4SiAYWrHLD7PQ0=');
  static final Uint8List _ivBytes = base64Decode('Gu3qsglYJhOOm0eXf6aN2w==');

  static final Key _key = Key(_keyBytes);
  static final IV _iv = IV(_ivBytes);
  static final Encrypter _encrypter = Encrypter(AES(_key, mode: AESMode.cbc, padding: 'PKCS7'));

  /// Mendekripsi payload base64 ciphertext yang dikembalikan oleh endpoint /enc/
  static dynamic dekripsiPayload(String ciphertextBase64) {
    if (ciphertextBase64.trim().isEmpty) return null;
    try {
      final decrypted = _encrypter.decrypt64(ciphertextBase64.trim(), iv: _iv);
      try {
        return jsonDecode(decrypted);
      } catch (_) {
        return decrypted;
      }
    } catch (_) {
      return null;
    }
  }

  /// Mengenkripsi plain ID menjadi format base64 yang diharapkan server
  static String enkripsiId(String plainId) {
    if (plainId.trim().isEmpty) return '';
    try {
      final encrypted = _encrypter.encrypt(plainId.trim(), iv: _iv);
      return encrypted.base64;
    } catch (_) {
      return plainId;
    }
  }

  /// Mendekripsi base64 ID menjadi string teks biasa
  static String dekripsiId(String encryptedId) {
    if (encryptedId.trim().isEmpty) return '';
    try {
      final decrypted = _encrypter.decrypt64(encryptedId.trim(), iv: _iv);
      return decrypted;
    } catch (_) {
      return encryptedId;
    }
  }
}
