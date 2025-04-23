// lib/main.dart
import 'package:flutter/material.dart';
import 'package:kasirku/config/routes.dart';
import 'package:kasirku/config/theme.dart';
import 'package:kasirku/providers/category_provider.dart';
import 'package:kasirku/providers/outlet_provider.dart';
import 'package:kasirku/providers/product_provider.dart';
import 'package:kasirku/providers/transaction_provider.dart';
import 'package:provider/provider.dart';
import './providers/auth_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => CategoryProvider()),
          ChangeNotifierProvider(create: (_) => ProductProvider()),
          ChangeNotifierProvider(create: (_) => TransactionProvider()),
          ChangeNotifierProvider(create: (_) => OutletProvider()),
        ],
        child: MaterialApp(
          title: 'KasirKu Pro',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          debugShowCheckedModeBanner: false,
          initialRoute: AppRouter.dashboard, //route pertamo kali app di bukak
          onGenerateRoute: AppRouter.generateRoute,//panggia konfigurasi routing
        )
    );
  }
}