import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ConsoleIdentity {
  const ConsoleIdentity({
    required this.nodeId,
    required this.fingerprint,
    required this.publicKeyBase64,
    required this.createdAt,
  });

  final String nodeId;
  final String fingerprint;
  final String publicKeyBase64;
  final DateTime createdAt;
}

class IdentityService {
  IdentityService({FlutterSecureStorage? storage})
      : _storage = storage ?? FlutterSecureStorage();

  static const _privateKeyKey = 'console.identity.ed25519.private';
  static const _publicKeyKey = 'console.identity.ed25519.public';
  static const _createdAtKey = 'console.identity.created_at';

  final FlutterSecureStorage _storage;
  final Ed25519 _algorithm = Ed25519();

  Future<ConsoleIdentity?> loadIdentity() async {
    final privateEncoded = await _storage.read(key: _privateKeyKey);
    final publicEncoded = await _storage.read(key: _publicKeyKey);
    final createdEncoded = await _storage.read(key: _createdAtKey);

    if (privateEncoded == null || publicEncoded == null || createdEncoded == null) {
      return null;
    }

    final publicBytes = base64Url.decode(publicEncoded);
    final createdAt = DateTime.tryParse(createdEncoded);
    if (publicBytes.length != 32 || createdAt == null) {
      return null;
    }

    return _identityFromPublicKey(publicBytes, createdAt);
  }

  Future<ConsoleIdentity> createIdentity() async {
    final keyPair = await _algorithm.newKeyPair();
    final privateBytes = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();
    final createdAt = DateTime.now().toUtc();

    await _storage.write(
      key: _privateKeyKey,
      value: base64Url.encode(privateBytes),
    );
    await _storage.write(
      key: _publicKeyKey,
      value: base64Url.encode(publicKey.bytes),
    );
    await _storage.write(
      key: _createdAtKey,
      value: createdAt.toIso8601String(),
    );

    return _identityFromPublicKey(publicKey.bytes, createdAt);
  }

  Future<SimpleKeyPairData?> loadSigningKeyPair() async {
    final privateEncoded = await _storage.read(key: _privateKeyKey);
    final publicEncoded = await _storage.read(key: _publicKeyKey);

    if (privateEncoded == null || publicEncoded == null) {
      return null;
    }

    final privateBytes = base64Url.decode(privateEncoded);
    final publicBytes = base64Url.decode(publicEncoded);

    if (privateBytes.length != 32 || publicBytes.length != 32) {
      return null;
    }

    return SimpleKeyPairData(
      privateBytes,
      publicKey: SimplePublicKey(publicBytes, type: KeyPairType.ed25519),
      type: KeyPairType.ed25519,
    );
  }

  Future<void> destroyLocalIdentity() async {
    await _storage.delete(key: _privateKeyKey);
    await _storage.delete(key: _publicKeyKey);
    await _storage.delete(key: _createdAtKey);
  }

  Future<ConsoleIdentity> _identityFromPublicKey(
    List<int> publicBytes,
    DateTime createdAt,
  ) async {
    final digest = await Sha256().hash(publicBytes);
    final nodeId = digest.bytes.take(5).map(_hexByte).join();
    final fingerprint = digest.bytes.take(12).map(_hexByte).join(':');

    return ConsoleIdentity(
      nodeId: nodeId,
      fingerprint: fingerprint,
      publicKeyBase64: base64Url.encode(publicBytes),
      createdAt: createdAt,
    );
  }

  String _hexByte(int value) => value.toRadixString(16).padLeft(2, '0').toUpperCase();
}
