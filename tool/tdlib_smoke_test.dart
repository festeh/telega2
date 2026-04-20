// Smoke test: loads libtdjson.so via FFI and calls a sync TDLib method.
// Exits 0 on success, non-zero on failure. No credentials or network required.
//
// Invoked by `just smoke-test-tdlib-linux` during `just migrate-tdlib`.

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

typedef _TdExecuteC = Pointer<Utf8> Function(Pointer client, Pointer<Utf8> req);
typedef _TdExecute = Pointer<Utf8> Function(Pointer client, Pointer<Utf8> req);

int _fail(String msg) {
  stderr.writeln('SMOKE FAIL: $msg');
  return 1;
}

void main() {
  final libPath = [
    'linux/lib/libtdjson.so',
    'libtdjson.so',
  ].firstWhere((p) => File(p).existsSync(), orElse: () => 'libtdjson.so');

  final DynamicLibrary lib;
  try {
    lib = DynamicLibrary.open(libPath);
  } catch (e) {
    exit(_fail('failed to open $libPath: $e'));
  }

  final execute =
      lib.lookup<NativeFunction<_TdExecuteC>>('td_json_client_execute').asFunction<_TdExecute>();

  final reqJson = jsonEncode({
    '@type': 'getTextEntities',
    'text': 'hello @telegram https://t.me',
  });
  final reqPtr = reqJson.toNativeUtf8();
  final Pointer<Utf8> respPtr;
  try {
    respPtr = execute(nullptr, reqPtr);
  } finally {
    calloc.free(reqPtr);
  }

  if (respPtr == nullptr) {
    exit(_fail('td_json_client_execute returned null'));
  }

  final resp = respPtr.toDartString();
  Map<String, dynamic> parsed;
  try {
    parsed = jsonDecode(resp) as Map<String, dynamic>;
  } catch (e) {
    exit(_fail('non-JSON response: $resp'));
  }

  if (parsed['@type'] != 'textEntities') {
    exit(_fail('unexpected response @type: ${parsed['@type']} (full: $resp)'));
  }
  final entities = parsed['entities'];
  if (entities is! List || entities.isEmpty) {
    exit(_fail('expected non-empty entities list, got: $entities'));
  }

  stdout.writeln(
    '    ✓ loaded $libPath, getTextEntities returned ${entities.length} entities',
  );
}
