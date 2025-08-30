// lib/providers/auth_provider.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/payment_item.dart';

// 영수증 전체를 표현하는 모델
class Receipt {
  final String id;
  final String store;
  final int totalAmount;
  DateTime purchaseDate;
  final List<PaymentItem> items;
  final File imageFile;
  bool isDateEstimated;

  Receipt({
    required this.id,
    required this.store,
    required this.totalAmount,
    required this.purchaseDate,
    required this.items,
    required this.imageFile,
    this.isDateEstimated = false,
  });
}

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isAuthenticated = false;
  bool _darkMode = false;

  final List<Receipt> _receipts = [];

  AuthProvider() {
    _loadUserData();
  }

  // Getters
  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get darkMode => _darkMode;
  List<Receipt> get receipts => _receipts;
  List<PaymentItem> get ingredients {
    final List<PaymentItem> allIngredients = [];
    for (var receipt in _receipts) {
      allIngredients.addAll(receipt.items.where((item) => item.category == '식자재'));
    }
    return allIngredients;
  }

  // Methods
  Future<void> login(String email, String password) async {
    // 가짜 로그인 로직 (서버 연동 시 실제 로직으로 교체)
    _user = User(email: email, name: '사용자');
    _isAuthenticated = true;
    await _saveUserData();
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    _isAuthenticated = false;
    _receipts.clear(); // 로그아웃 시 영수증 데이터도 초기화
    await _clearUserData();
    notifyListeners();
  }

  Future<void> setDarkMode(bool isDark) async {
    _darkMode = isDark;
    await _saveDarkMode();
    notifyListeners();
  }

  Future<Receipt> addReceiptFromJson(Map<String, dynamic> jsonData, File imageFile) async {
    try {
      DateTime purchaseDate;
      bool isDateEstimated = false;
      final purchaseDateString = jsonData['purchaseDate'] as String?;
      if (purchaseDateString == null) {
        purchaseDate = DateTime.now();
        isDateEstimated = true;
      } else {
        purchaseDate = DateTime.parse(purchaseDateString);
      }
      final store = jsonData['store'] as String? ?? '알 수 없는 매장';
      final totalAmount = jsonData['totalAmount'] as int? ?? 0;
      final itemsData = jsonData['items'] as List? ?? [];
      final List<PaymentItem> parsedItems = itemsData.map((itemJson) {
        final item = itemJson as Map<String, dynamic>;
        return PaymentItem(
          id: '${purchaseDate.millisecondsSinceEpoch}-${item['name']}',
          name: item['name'] as String? ?? '이름 없는 상품',
          category: item['category'] as String? ?? '기타',
          amount: item['price'] as int? ?? 0,
          purchaseDate: DateFormat('yyyy-MM-dd').format(purchaseDate),
          expiryDate: item['expiryDate'] as String?,
          storageMethod: '냉장 보관',
        );
      }).toList();
      final newReceipt = Receipt(
        id: purchaseDate.millisecondsSinceEpoch.toString(),
        store: store,
        totalAmount: totalAmount,
        purchaseDate: purchaseDate,
        items: parsedItems,
        imageFile: imageFile,
        isDateEstimated: isDateEstimated,
      );
      _receipts.add(newReceipt);
      notifyListeners();
      return newReceipt;
    } catch (e) {
      print('영수증 데이터 파싱 오류: $e');
      throw Exception('영수증 데이터 처리 중 오류가 발생했습니다.');
    }
  }
  
  Future<void> updateReceiptDate(String receiptId, DateTime newDate) async {
    try {
      final receiptIndex = _receipts.indexWhere((r) => r.id == receiptId);
      if (receiptIndex != -1) {
        _receipts[receiptIndex].purchaseDate = newDate;
        _receipts[receiptIndex].isDateEstimated = false;
        notifyListeners();
      }
    } catch (e) {
      print('영수증 날짜 업데이트 오류: $e');
    }
  }

  Future<bool> deleteIngredientByName(String name) async {
    bool deleted = false;
    for (var receipt in _receipts) {
      final initialLength = receipt.items.length;
      receipt.items.removeWhere((item) => item.name == name && item.category == '식자재');
      if (receipt.items.length < initialLength) {
        deleted = true;
      }
    }
    if (deleted) {
      notifyListeners();
    }
    return deleted;
  }

  // --- Private SharedPreferences Logic ---
  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAuthenticated', _isAuthenticated);
    await prefs.setString('userEmail', _user?.email ?? '');
    await prefs.setString('userName', _user?.name ?? '');
  }

  Future<void> _saveDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _darkMode);
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
    if (_isAuthenticated) {
      final email = prefs.getString('userEmail');
      final name = prefs.getString('userName');
      if (email != null && name != null) {
        _user = User(email: email, name: name);
      }
    }
    _darkMode = prefs.getBool('darkMode') ?? false;
    notifyListeners();
  }

  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
  /// 식자재(품목) 하나를 ID로 찾아 삭제하고 UI를 갱신합니다.
  void removeItemById(String itemId) {
    for (final receipt in _receipts) {
      final idx = receipt.items.indexWhere((e) => e.id == itemId);
      if (idx != -1) {
        receipt.items.removeAt(idx);
        notifyListeners();
        return;
      }
    }
  }

}