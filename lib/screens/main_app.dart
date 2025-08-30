// lib/screens/main_app.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'chat_screen.dart';
import 'receipt_detail_screen.dart';
import '../models/payment_item.dart';

// --- 화면 구현 ---

class PaymentListScreen extends StatelessWidget {
  const PaymentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('결제목록')),
          body: authProvider.receipts.isEmpty
              ? const Center(child: Text('아직 등록된 영수증이 없습니다.'))
              : ListView.builder(
                  itemCount: authProvider.receipts.length,
                  itemBuilder: (context, index) {
                    final receipt = authProvider.receipts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(receipt.store),
                        subtitle: Text('구매일: ${DateFormat('yyyy-MM-dd').format(receipt.purchaseDate)}'),
                        trailing: Text('${NumberFormat('#,###').format(receipt.totalAmount)}원'),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ReceiptDetailScreen(receipt: receipt),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class IngredientsScreen extends StatelessWidget {
  const IngredientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final ingredients = authProvider.ingredients;
        return Scaffold(
          appBar: AppBar(title: const Text('식자재')),
          body: ingredients.isEmpty
              ? const Center(child: Text('아직 등록된 식자재가 없습니다.'))
              : ListView.builder(
                  itemCount: ingredients.length,
                  itemBuilder: (context, index) {
                    final item = ingredients[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(item.name),
                        subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.expiryFormatted != null) Text('유통기한: ${item.expiryFormatted}'),
                        ],
                      ),
                        trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.isExpired)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.08),
                                border: Border.all(color: Colors.red),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('유통기한 지남', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          const SizedBox(width: 8),
                          Text('${NumberFormat('#,###').format(item.amount)}원'),
                          IconButton(
                            tooltip: '삭제',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('품목 삭제'),
                                  content: Text('“${item.name}”을(를) 삭제할까요?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
                                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제')),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                authProvider.removeItemById(item.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('삭제됨: ${item.name}')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('설정')),
          body: ListView(
            children: [
              if (authProvider.isAuthenticated && authProvider.user != null)
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(authProvider.user!.name),
                  subtitle: Text(authProvider.user!.email),
                ),
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode),
                title: const Text('다크 모드'),
                value: authProvider.darkMode,
                onChanged: (value) {
                  authProvider.setDarkMode(value);
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('로그아웃', style: TextStyle(color: Colors.red)),
                onTap: () {
                  authProvider.logout();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- 메인 앱 구조 ---

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const PaymentListScreen(),
    const IngredientsScreen(),
    const ChatScreen(), 
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: '결제목록'),
          BottomNavigationBarItem(icon: Icon(Icons.eco), label: '식자재'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: '채팅'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}