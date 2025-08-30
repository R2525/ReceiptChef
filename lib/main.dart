// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/main_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyRoot());
}

class MyRoot extends StatelessWidget {
  const MyRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: Consumer<AuthProvider>(
        builder: (_, auth, __) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.indigo,
                brightness: Brightness.light,
              ),
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.indigo,
                brightness: Brightness.dark,
              ),
              brightness: Brightness.dark,
            ),
            themeMode: auth.darkMode ? ThemeMode.dark : ThemeMode.light,
            home: const MainApp(),
          );
        },
      ),
    );
  }
}