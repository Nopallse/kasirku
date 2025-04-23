import 'package:flutter/material.dart';
import 'package:kasirku/ui/screens/cashier/held_orders_screen.dart';

import '../ui/screens/main_screen.dart';
import '../ui/screens/dashboard/dashboard_screen.dart';
import '../ui/screens/cashier/cashier_screen.dart';
import '../ui/screens/transaction/transaction_details_screen.dart';
import '../ui/screens/transaction/transaction_history_screen.dart';
import '../ui/screens/management/management_screen.dart';
import '../ui/screens/management/products/add_product_screen.dart';
import '../ui/screens/management/products/edit_product_screen.dart';
import '../ui/screens/management/categories/add_category_screen.dart';

class AppRouter {
  // Root routes
  static const String dashboard = '/dashboard';
  static const String cashier = '/cashier';
  static const String reports = '/reports';

  // Management routes
  static const String management = '/management';
  static const String products = '/products';
  static const String addProduct = '/products/add';
  static const String editProduct = '/products/edit';

  static const String categories = '/categories';
  static const String addCategory = '/categories/add';

  static const String employees = '/employees';
  static const String addEmployee = '/employees/add';

  static const String outlets = '/outlets';
  static const String addOutlet = '/outlets/add';

  // Transaction routes
  static const String transactionDetails = '/transaction/details';
  static const String transactionHistory = '/transaction/history';
  static const String heldOrders = '/transaction/held-orders';

  static const String BalanceSheet = '/balance-sheet';
  static const String GeneralLedger = '/general-ledger';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case dashboard:
        return MaterialPageRoute(
          builder:
              (_) =>
                  MainScreen(initialIndex: 0, child: const DashboardScreen()),
        );

      case cashier:
        return MaterialPageRoute(
          builder:
              (_) => MainScreen(initialIndex: 1, child: const CashierScreen()),
        );

      case management:
        return MaterialPageRoute(
          builder:
              (_) =>
                  MainScreen(initialIndex: 2, child: const ManagementScreen()),
        );

      case transactionHistory:
        return MaterialPageRoute(
          builder:
              (_) => MainScreen(
                initialIndex: 3,
                child: const TransactionHistoryScreen(),
              ),
        );

      case heldOrders:
        return MaterialPageRoute(builder: (_) => const HeldOrdersScreen());

      case reports:
        return MaterialPageRoute(
          builder:
              (_) => MainScreen(
                initialIndex: 4,
                child: const TransactionHistoryScreen(),
              ),
        );

      // Product routes
      case addProduct:
        return MaterialPageRoute(builder: (_) => const AddProductScreen());

      case editProduct:
        final args = settings.arguments as Map<String, dynamic>?;
        final productId = args?['productId'] as int?;
        if (productId != null) {
          return MaterialPageRoute(
            builder: (_) => EditProductScreen(productId: productId),
          );
        }
        return _errorRoute();

      case addCategory:
        return MaterialPageRoute(builder: (_) => const AddCategoryScreen());

      // Transaction routes
      case transactionDetails:
        final transactionId = settings.arguments as int?;
        if (transactionId != null) {
          return MaterialPageRoute(
            builder:
                (_) => TransactionDetailsScreen(transactionId: transactionId),
          );
        }
        return _errorRoute();

      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) {
        return Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: const Center(child: Text('Page not found!')),
        );
      },
    );
  }
}
