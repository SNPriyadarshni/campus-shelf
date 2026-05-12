import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/item_model.dart';
import '../models/message_model.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api'; // Use your machine's IP for physical devices
  static const _storage = FlutterSecureStorage();

  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- Auth ---
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      await _storage.write(key: 'jwt_token', value: data['token']);
      return data;
    } else {
      throw Exception(data['message'] ?? 'Login failed');
    }
  }

  static Future<Map<String, dynamic>> register(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      await _storage.write(key: 'jwt_token', value: data['token']);
      return data;
    } else {
      throw Exception(data['message'] ?? 'Registration failed');
    }
  }

  static Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  // --- Items ---
  static Future<List<ItemModel>> getItems({
    String? category,
    bool? freeOnly,
    String? search,
    String? userEmail,
  }) async {
    final queryParams = {
      if (category != null) 'category': category,
      if (freeOnly != null) 'freeOnly': freeOnly.toString(),
      if (search != null) 'search': search,
      if (userEmail != null) 'userEmail': userEmail,
    };

    final uri = Uri.parse('$baseUrl/items').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((item) {
        // MongoDB uses _id, but our model uses id
        Map<String, dynamic> itemData = Map<String, dynamic>.from(item);
        itemData['id'] = itemData['_id'];
        return ItemModel.fromMap(itemData);
      }).toList();
    } else {
      throw Exception('Failed to load items');
    }
  }

  static Future<ItemModel> addItem(ItemModel item) async {
    final response = await http.post(
      Uri.parse('$baseUrl/items'),
      headers: await _getHeaders(),
      body: jsonEncode(item.toMap()),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      data['id'] = data['_id'];
      return ItemModel.fromMap(data);
    } else {
      throw Exception('Failed to add item');
    }
  }

  static Future<void> deleteItem(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/items/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete item');
    }
  }

  // --- Messages ---
  static Future<List<MessageModel>> getMessages(String email) async {
    final uri = Uri.parse('$baseUrl/messages').replace(queryParameters: {'email': email});
    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((msg) {
        Map<String, dynamic> msgData = Map<String, dynamic>.from(msg);
        msgData['id'] = msgData['_id'];
        return MessageModel.fromMap(msgData);
      }).toList();
    } else {
      throw Exception('Failed to load messages');
    }
  }
  
  static Future<List<MessageModel>> getItemMessages(String itemId) async {
    final uri = Uri.parse('$baseUrl/messages/item/$itemId');
    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((msg) {
        Map<String, dynamic> msgData = Map<String, dynamic>.from(msg);
        msgData['id'] = msgData['_id'];
        return MessageModel.fromMap(msgData);
      }).toList();
    } else {
      throw Exception('Failed to load item messages');
    }
  }

  static Future<void> sendMessage(Map<String, dynamic> messageData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/messages'),
      headers: await _getHeaders(),
      body: jsonEncode(messageData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send message');
    }
  }

  // --- Item Status ---
  static Future<void> updateItemStatus(String itemId, String status, {String? buyerEmail}) async {
    final body = <String, dynamic>{
      'status': status,
    };
    if (buyerEmail != null) {
      body['buyerEmail'] = buyerEmail;
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/items/$itemId/status'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update item status');
    }
  }
}
