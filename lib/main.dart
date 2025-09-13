import 'dart:async';
import 'dart:convert';
import 'package:bigdata_natural_disaster/pages/landing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// URL del backend.
const String kDefaultApiBase = 'http://localhost:8000';
const String kApiBase = String.fromEnvironment('API_BASE_URL', defaultValue: kDefaultApiBase);

/// Client HTTP centralizzato.
class Api {
  Api._(this.baseUrl, this._client);
  final String baseUrl;
  final http.Client _client;

  static late final Api I;

  /// Inizializzazione globale (da chiamare nel main)
  static void init({required String baseUrl}) {
    I = Api._(baseUrl, http.Client());
  }

  Uri _u(String path, [Map<String, dynamic>? q]) =>
      Uri.parse(baseUrl).resolve(path).replace(queryParameters: q?.map((k, v) => MapEntry(k, '$v')));

  Future<http.Response> get(String path, {Map<String, dynamic>? query}) =>
      _client.get(_u(path, query));

  Future<http.Response> post(String path, {Object? body, Map<String, String>? headers}) =>
      _client.post(_u(path),
          body: body is String ? body : jsonEncode(body ?? {}),
          headers: {
            'content-type': 'application/json',
            ...?headers,
          });

  /// health-check 
  Future<bool> healthCheck({String path = '/health'}) async {
    try {
      final r = await _client.get(_u(path)).timeout(const Duration(seconds: 3));
      return r.statusCode >= 200 && r.statusCode < 300;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza il client verso il backend
  Api.init(baseUrl: kApiBase);

  // Ping in debug per loggare lo stato del backend
  if (kDebugMode) {
    unawaited(() async {
      final ok = await Api.I.healthCheck(path: '/health'); 
      print('[API] ${Api.I.baseUrl} — health: ${ok ? 'OK' : 'KO'}');
    }());
  }

  runApp(const BigDataApp());
}

class BigDataApp extends StatelessWidget {
  const BigDataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BigData Frontend',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey)),
      home: const HomePage(), 
    );
  }
}


