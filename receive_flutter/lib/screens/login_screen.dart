// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin(AuthProvider authProvider) async {
    if (_emailController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      // authProvider의 login 함수가 Future를 반환하므로 await로 기다립니다.
      await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // 위젯이 화면에 계속 표시되어 있을 경우에만 setState를 호출합니다.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = authProvider.darkMode;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [Colors.grey[900]!, Colors.grey[800]!]
              : [Colors.green[50]!, Colors.blue[50]!],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              margin: EdgeInsets.all(16),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: isDark ? Colors.green[900] : Colors.green[100],
                      child: Icon(Icons.receipt, size: 32, color: isDark ? Colors.green[400] : Colors.green[600]),
                    ),
                    SizedBox(height: 16),
                    Text('영수증 분석 앱', style: Theme.of(context).textTheme.headlineSmall),
                    SizedBox(height: 8),
                    Text('로그인하여 식습관을 관리하세요', style: Theme.of(context).textTheme.bodyMedium),
                    SizedBox(height: 24),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: '이메일', border: OutlineInputBorder()),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(labelText: '비밀번호', border: OutlineInputBorder()),
                      obscureText: true,
                    ),
                    SizedBox(height: 24),
                    _isLoading
                        ? CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _handleLogin(authProvider),
                              child: Text('로그인'),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}