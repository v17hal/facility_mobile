import "package:dio/dio.dart";

import "api_client.dart";

class ApiService {
  ApiService(this._client);

  final ApiClient _client;

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? params}) {
    return _client.dio.get(path, queryParameters: params);
  }

  Future<Response<dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? params,
  }) {
    return _client.dio.post(path, data: data, queryParameters: params);
  }

  Future<Response<dynamic>> patch(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? params,
  }) {
    return _client.dio.patch(path, data: data, queryParameters: params);
  }

  Future<Response<dynamic>> delete(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? params,
  }) {
    return _client.dio.delete(path, data: data, queryParameters: params);
  }
}
