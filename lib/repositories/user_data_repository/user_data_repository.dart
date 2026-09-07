import 'dart:convert';

import 'package:ccc_flutter/auth_config.dart';
import 'package:ccc_flutter/models/user_data.dart';
import 'package:http/http.dart' as http;

/// Client for the Google-authenticated user data sync API
/// (API Gateway HTTP API + Lambda + DynamoDB in the carte-cantari-backend repo).
class UserDataRepository {
  final String _apiUrl;

  UserDataRepository({String? apiUrl}) : _apiUrl = apiUrl ?? USER_DATA_API_URL;

  /// Returns the stored user data, or null if the account has none yet
  /// (i.e. this is the account's first login).
  Future<UserData?> fetchUserData(String idToken) async {
    final response = await http.get(
      Uri.parse(_apiUrl),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode == 200) {
      return UserData.fromJson(json.decode(response.body));
    }
    if (response.statusCode == 404) {
      return null;
    }
    throw Exception('Failed to fetch user data (${response.statusCode})');
  }

  Future<void> storeUserData(String idToken, UserData data) async {
    final response = await http.put(
      Uri.parse(_apiUrl),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: json.encode(data.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to store user data (${response.statusCode})');
    }
  }
}
