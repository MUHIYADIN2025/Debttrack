// ================================================================
// DebtTrack Flutter — API Service
// File: lib/services/api_service.dart
// ================================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

const String baseUrl = 'http://YOUR_SERVER_IP:3000/api';

// ── API Service (ChangeNotifier for state) ────────────────────────
class ApiService extends ChangeNotifier {
  String? _token;

  void setToken(String? token) {
    _token = token;
    notifyListeners();
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ── Generic request helper ────────────────────────────────────
  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    Uri uri = Uri.parse('$baseUrl$path');
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams);
    }

    http.Response response;
    final bodyJson = body != null ? jsonEncode(body) : null;

    switch (method) {
      case 'GET':    response = await http.get(uri, headers: _headers); break;
      case 'POST':   response = await http.post(uri, headers: _headers, body: bodyJson); break;
      case 'PATCH':  response = await http.patch(uri, headers: _headers, body: bodyJson); break;
      case 'DELETE': response = await http.delete(uri, headers: _headers); break;
      default: throw Exception('Unknown HTTP method: $method');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw ApiException(data['message'] ?? 'Request failed', response.statusCode);
    }
    return data;
  }

  // ── CUSTOMERS ──────────────────────────────────────────────────
  Future<List<Customer>> getCustomers({String? search}) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final data = await _request('GET', '/customers', queryParams: params);
    return (data['data'] as List).map((j) => Customer.fromJson(j)).toList();
  }

  Future<Customer> getCustomer(String id) async {
    final data = await _request('GET', '/customers/$id');
    return Customer.fromJson(data['data']);
  }

  Future<Customer> createCustomer(Map<String, dynamic> body) async {
    final data = await _request('POST', '/customers', body: body);
    return Customer.fromJson(data['data']);
  }

  Future<Customer> updateCustomer(String id, Map<String, dynamic> body) async {
    final data = await _request('PATCH', '/customers/$id', body: body);
    return Customer.fromJson(data['data']);
  }

  Future<void> deleteCustomer(String id) async {
    await _request('DELETE', '/customers/$id');
  }

  // ── DEBTS ──────────────────────────────────────────────────────
  Future<List<Debt>> getDebts({String? customerId, String? status}) async {
    final params = <String, String>{};
    if (customerId != null) params['customerId'] = customerId;
    if (status != null)     params['status'] = status;
    final data = await _request('GET', '/debts', queryParams: params);
    return (data['data'] as List).map((j) => Debt.fromJson(j)).toList();
  }

  Future<Debt> createDebt(Map<String, dynamic> body) async {
    final data = await _request('POST', '/debts', body: body);
    return Debt.fromJson(data['data']);
  }

  Future<void> deleteDebt(String id) async {
    await _request('DELETE', '/debts/$id');
  }

  // ── PAYMENTS ───────────────────────────────────────────────────
  Future<List<Payment>> getPayments({String? customerId}) async {
    final params = <String, String>{};
    if (customerId != null) params['customerId'] = customerId;
    final data = await _request('GET', '/payments', queryParams: params);
    return (data['data'] as List).map((j) => Payment.fromJson(j)).toList();
  }

  Future<Map<String, dynamic>> recordPayment(Map<String, dynamic> body) async {
    return _request('POST', '/payments', body: body);
  }

  // ── DASHBOARD ──────────────────────────────────────────────────
  Future<DashboardStats> getDashboard() async {
    final data = await _request('GET', '/dashboard');
    return DashboardStats.fromJson(data['data']);
  }

  // ── REPORTS ────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getCustomerReport() async {
    final data = await _request('GET', '/reports/customers');
    return List<Map<String, dynamic>>.from(data['data']);
  }

  Future<List<Payment>> getPaymentReport({String? from, String? to}) async {
    final params = <String, String>{};
    if (from != null) params['from'] = from;
    if (to != null)   params['to']   = to;
    final data = await _request('GET', '/reports/payments', queryParams: params);
    return (data['data'] as List).map((j) => Payment.fromJson(j)).toList();
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
  @override String toString() => message;
}

// ================================================================
// Auth Service
// File: lib/services/auth_service.dart
// ================================================================

class AuthService extends ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = true;

  User?   get user      => _user;
  String? get token     => _token;
  bool    get isLoggedIn => _user != null;
  bool    get isLoading  => _isLoading;
  bool    get isAdmin    => _user?.role == 'Admin';

  AuthService() { _loadFromStorage(); }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tokenStr = prefs.getString('auth_token');
      final userStr  = prefs.getString('auth_user');
      if (tokenStr != null && userStr != null) {
        _token = tokenStr;
        _user  = User.fromJson(jsonDecode(userStr));
      }
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password, ApiService api) async {
    final data = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final json = jsonDecode(data.body) as Map<String, dynamic>;
    if (data.statusCode != 200) throw Exception(json['message']);

    _token = json['token'];
    _user  = User.fromJson(json['user']);
    api.setToken(_token);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', _token!);
    await prefs.setString('auth_user',  jsonEncode(json['user']));
    notifyListeners();
  }

  Future<void> register(Map<String, String> fields, ApiService api) async {
    final data = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(fields),
    );

    final json = jsonDecode(data.body) as Map<String, dynamic>;
    if (data.statusCode != 201) throw Exception(json['message']);

    _token = json['token'];
    _user  = User.fromJson(json['user']);
    api.setToken(_token);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', _token!);
    await prefs.setString('auth_user',  jsonEncode(json['user']));
    notifyListeners();
  }

  Future<void> logout() async {
    _user  = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
    notifyListeners();
  }
}
