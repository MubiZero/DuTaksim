import 'package:dio/dio.dart';
import '../config/constants.dart';
import '../models/user.dart';
import '../models/bill.dart';
import '../models/session.dart';
import 'storage_service.dart';

class ApiService {
  final Dio _dio;

  ApiService()
      : _dio = Dio(BaseOptions(
          baseUrl: Constants.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
          },
        )) {
    // Add interceptor to attach auth token to all requests
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await StorageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  // User APIs
  Future<User> registerUser(String name, String phone) async {
    try {
      final response = await _dio.post('/users/register', data: {
        'name': name,
        'phone': phone,
      });

      // Save JWT token if provided
      final token = response.data['token'];
      if (token != null) {
        await StorageService.saveToken(token);
      }

      return User.fromJson(response.data['user']);
    } catch (e) {
      throw Exception('Failed to register user: $e');
    }
  }

  Future<User> getUserByPhone(String phone) async {
    try {
      final response = await _dio.get('/users/phone/$phone');
      return User.fromJson(response.data['user']);
    } catch (e) {
      throw Exception('Failed to fetch user: $e');
    }
  }

  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final response = await _dio.get('/users/$userId/stats');
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch user stats: $e');
    }
  }

  // Bill APIs
  Future<Bill> createBill({
    required String title,
    String? description,
    required double totalAmount,
    required String paidBy,
    required double tips,
    required List<String> participants,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await _dio.post('/bills', data: {
        'title': title,
        'description': description,
        'totalAmount': totalAmount,
        'paidBy': paidBy,
        'tips': tips,
        'participants': participants,
        'items': items,
      });
      return Bill.fromJson(response.data['bill']);
    } catch (e) {
      throw Exception('Failed to create bill: $e');
    }
  }

  Future<List<Bill>> getUserBills(String userId) async {
    try {
      final response = await _dio.get('/bills/user/$userId');
      final bills = (response.data['bills'] as List)
          .map((bill) => Bill.fromJson(bill))
          .toList();
      return bills;
    } catch (e) {
      throw Exception('Failed to fetch bills: $e');
    }
  }

  Future<Bill> getBillById(String billId) async {
    try {
      print('API Service - Getting bill: $billId');
      final response = await _dio.get('/bills/$billId');
      print('API Service - Bill response: ${response.data}');

      final billData = response.data['bill'];
      print('API Service - Bill items: ${billData['items']}');

      return Bill.fromJson(billData);
    } catch (e) {
      print('API Service - Error getting bill: $e');
      throw Exception('Failed to fetch bill: $e');
    }
  }

  Future<void> markDebtAsPaid(String debtId) async {
    try {
      await _dio.patch('/bills/debts/$debtId/pay');
    } catch (e) {
      throw Exception('Failed to mark debt as paid: $e');
    }
  }

  // Transaction APIs
  Future<Map<String, dynamic>> getUserTransactions(String userId) async {
    try {
      final response = await _dio.get('/transactions/user/$userId');
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch transactions: $e');
    }
  }

  // Session APIs
  Future<BillSession> createSession({
    required String name,
    required String creatorId,
    double? latitude,
    double? longitude,
    int? radius,
  }) async {
    try {
      final data = {
        'name': name,
        'creatorId': creatorId,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius ?? 50,
      };
      print('API Service - Sending data: $data');

      final response = await _dio.post('/sessions/create', data: data);
      print('API Service - Response: ${response.data}');

      return BillSession.fromJson(response.data);
    } catch (e) {
      print('API Service - Error: $e');
      if (e is DioException) {
        print('API Service - DioError response: ${e.response?.data}');
        print('API Service - DioError statusCode: ${e.response?.statusCode}');
      }
      throw Exception('Failed to create session: $e');
    }
  }

  Future<List<BillSession>> getNearbySessions({
    required double latitude,
    required double longitude,
    int? radius,
  }) async {
    try {
      final response = await _dio.get('/sessions/nearby', queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius ?? 100,
      });
      return (response.data as List)
          .map((session) => BillSession.fromJson(session))
          .toList();
    } catch (e) {
      throw Exception('Failed to get nearby sessions: $e');
    }
  }

  Future<BillSession> joinSession({
    String? sessionCode,
    String? sessionId,
    required String userId,
  }) async {
    try {
      print('API Service - Joining session:');
      print('  sessionCode: $sessionCode');
      print('  sessionId: $sessionId');
      print('  userId: $userId');

      final response = await _dio.post('/sessions/join', data: {
        if (sessionCode != null) 'sessionCode': sessionCode,
        if (sessionId != null) 'sessionId': sessionId,
        'userId': userId,
      });

      print('API Service - Join response: ${response.data}');
      return BillSession.fromJson(response.data);
    } catch (e) {
      print('API Service - Join error: $e');
      throw Exception('Failed to join session: $e');
    }
  }

  Future<BillSession> getSession(String sessionId) async {
    try {
      final response = await _dio.get('/sessions/$sessionId');
      return BillSession.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get session: $e');
    }
  }

  Future<SessionItem> addSessionItem({
    required String sessionId,
    required String name,
    required double price,
    required String addedBy,
    String? forUserId,
    bool? isShared,
  }) async {
    try {
      final response = await _dio.post('/sessions/$sessionId/items', data: {
        'name': name,
        'price': price,
        'addedBy': addedBy,
        'forUserId': forUserId,
        'isShared': isShared ?? false,
      });
      return SessionItem.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to add item: $e');
    }
  }

  Future<List<SessionItem>> getSessionItems(String sessionId) async {
    try {
      final response = await _dio.get('/sessions/$sessionId/items');
      return (response.data as List)
          .map((item) => SessionItem.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to get session items: $e');
    }
  }

  Future<void> deleteSessionItem(String sessionId, String itemId) async {
    try {
      await _dio.delete('/sessions/$sessionId/items/$itemId');
    } catch (e) {
      throw Exception('Failed to delete item: $e');
    }
  }

  Future<Map<String, dynamic>> finalizeSession({
    required String sessionId,
    String? title,
    String? description,
    required String paidBy,
    double? tips,
  }) async {
    try {
      final response = await _dio.post('/sessions/$sessionId/finalize', data: {
        'title': title,
        'description': description,
        'paidBy': paidBy,
        'tips': tips ?? 0,
      });
      return response.data;
    } catch (e) {
      throw Exception('Failed to finalize session: $e');
    }
  }

  Future<void> closeSession(String sessionId) async {
    try {
      await _dio.post('/sessions/$sessionId/close');
    } catch (e) {
      throw Exception('Failed to close session: $e');
    }
  }

  // Contact APIs
  Future<Map<String, dynamic>> lookupContacts(List<String> phones) async {
    try {
      final response = await _dio.post('/contacts/lookup', data: {
        'phones': phones,
      });
      return response.data;
    } catch (e) {
      throw Exception('Failed to lookup contacts: $e');
    }
  }

  Future<Map<String, dynamic>> inviteContact({
    required String inviterId,
    required String phone,
    String? sessionId,
  }) async {
    try {
      final response = await _dio.post('/contacts/invite', data: {
        'inviterId': inviterId,
        'phone': phone,
        'sessionId': sessionId,
      });
      return response.data;
    } catch (e) {
      throw Exception('Failed to invite contact: $e');
    }
  }

  Future<Map<String, dynamic>> addParticipantsToSession({
    required String sessionId,
    required List<String> userIds,
    bool sendInvites = false,
  }) async {
    try {
      final response = await _dio.post(
        '/contacts/sessions/$sessionId/add-participants',
        data: {
          'userIds': userIds,
          'sendInvites': sendInvites,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to add participants: $e');
    }
  }
}
