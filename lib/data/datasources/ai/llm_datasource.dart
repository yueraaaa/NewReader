import 'dart:convert';
import 'package:http/http.dart' as http;

class LlmDatasource {
  final String apiKey;
  final String baseUrl;
  final String modelId;
  final http.Client _client;

  LlmDatasource({
    required this.apiKey,
    required this.baseUrl,
    required this.modelId,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Test connection to the LLM API by sending a simple completion request
  Future<LlmConnectionResult> testConnection() async {
    if (apiKey.isEmpty || baseUrl.isEmpty || modelId.isEmpty) {
      return LlmConnectionResult(
        success: false,
        message: '请填写完整的 API Key、Base URL 和 Model ID',
      );
    }

    try {
      final uri = Uri.parse(baseUrl);
      final response = await _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': modelId,
          'messages': [
            {'role': 'user', 'content': 'Hi'}
          ],
          'max_tokens': 5,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final model = data['model'] ?? modelId;
        return LlmConnectionResult(
          success: true,
          message: '连接成功！使用模型: $model',
        );
      } else {
        final errorBody = _parseErrorBody(response.body);
        return LlmConnectionResult(
          success: false,
          message: '连接失败 (${response.statusCode}): $errorBody',
        );
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (e.toString().contains('Connection refused')) {
        errorMessage = '无法连接到服务器，请检查 Base URL 是否正确';
      } else if (e.toString().contains('timeout')) {
        errorMessage = '连接超时，请检查网络和 Base URL';
      }
      return LlmConnectionResult(
        success: false,
        message: '连接错误: $errorMessage',
      );
    }
  }

  String _parseErrorBody(String body) {
    try {
      final data = jsonDecode(body);
      return data['error']?['message'] ?? data['error'] ?? body;
    } catch (_) {
      return body.length > 100 ? '${body.substring(0, 100)}...' : body;
    }
  }
}

class LlmConnectionResult {
  final bool success;
  final String message;

  LlmConnectionResult({
    required this.success,
    required this.message,
  });
}