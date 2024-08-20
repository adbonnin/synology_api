part of '../synology_api.dart';

class ApiClient {
  const ApiClient(this.baseUri, this.client);

  final Uri baseUri;
  final http.Client client;

  Future<T> send<T>(
    String path, {
    String? api,
    String? version,
    String? method,
  }) async {
    if (path.startsWith('/')) {
      path = path.substring(1);
    }

    final uri = Uri.parse(path);
    final request = http.Request('GET', uri);

    final response = await http.Response.fromStream(await client.send(request));
    ApiException.checkResponse(response);

    final decoded = _decode(response, T);
    return decoded as T;
  }

  dynamic _decode(http.Response response, Type responseType) {
    final bytes = response.bodyBytes;
    final responseBytes = utf8.decode(bytes);

    return jsonDecode(responseBytes);
  }

  void close() {
    client.close();
  }
}

class ApiException implements Exception {
  const ApiException(
      this.url,
      this.statusCode,
      this.reasonPhrase, {
        this.code,
        this.errors,
      });

  final Uri? url;
  final int statusCode;
  final String? reasonPhrase;
  final int? code;
  final List<ErrorDetail>? errors;

  factory ApiException.fromResponse(http.Response response) {
    int? code;
    List<ErrorDetail>? errors;

    if (response.body.isNotEmpty) {
      try {
        final decodedBody = jsonDecode(response.body);

        if (decodedBody is Map<String, dynamic>) {
          final errorBody = decodedBody['error'];

          if (errorBody is Map<String, dynamic>) {
            code = errorBody['code'] as int?;
            errors = errorBody['errors'] as List<String>?;
          }
        }
      } //
      catch (e) {
        // Fail to parse as Json
      }
    }

    return ApiException(
      response.request?.url,
      response.statusCode,
      response.reasonPhrase,
      code: code,
      errors: errors,
    );
  }

  @override
  String toString() {
    return 'ApiException($statusCode, $reasonPhrase, '
        'url: $url, '
        'code: $code, '
        'errors: $errors)';
  }

  static void checkResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 400) {
      return;
    }

    throw ApiException.fromResponse(response);
  }
}

class ErrorDetail {
  final int? code;
  final Map<String, dynamic> information;
}