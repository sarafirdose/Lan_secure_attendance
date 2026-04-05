import 'dart:async';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class AuthenticatedClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Inject current token before sending
    final token = await AuthService.getToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Capture the request in case we need to retry
    // Since http.BaseRequest is single-use if it's a stream, we might need a workaround.
    // However, for typical fast json payloads, this standard retry works:
    http.StreamedResponse response = await _inner.send(request)
        .timeout(const Duration(seconds: 5));

    // If 401 Unauthorized, intercept and attempt a silent token refresh
    if (response.statusCode == 401) {
      final retryRequest = _copyRequest(request);
      
      // Concurrency Lock: If already refreshing, wait for it to finish
      if (_isRefreshing) {
        if (_refreshCompleter != null) {
          await _refreshCompleter!.future;
        }
      } else {
        _isRefreshing = true;
        _refreshCompleter = Completer<void>();
        
        try {
          final success = await AuthService.refreshToken();
          if (!success) {
            await AuthService.signOut(); // Infinite loop prevention + safety
          }
        } finally {
          _isRefreshing = false;
          _refreshCompleter!.complete();
          _refreshCompleter = null;
        }
      }

      // Retry the intercepted request with the NEW token
      final newToken = await AuthService.getToken();
      if (newToken != null && newToken.isNotEmpty) {
        retryRequest.headers['Authorization'] = 'Bearer $newToken';
      }
      return _inner.send(retryRequest);
    }

    return response;
  }

  // Helper to clone request because an HTTP request can only be sent once 
  http.BaseRequest _copyRequest(http.BaseRequest request) {
    if (request is http.Request) {
      final req = http.Request(request.method, request.url)
        ..headers.addAll(request.headers)
        ..encoding = request.encoding
        ..bodyBytes = request.bodyBytes;
      return req;
    }
    // Fallback if Multipart 
    return request;
  }
}
