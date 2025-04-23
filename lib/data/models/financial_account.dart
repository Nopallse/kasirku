// lib/data/models/financial_account.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Account Type enum
enum AccountType {
  asset,      // Aset
  liability,  // Kewajiban
  equity,     // Ekuitas
  revenue,    // Pendapatan
  expense     // Beban
}

// Account class
class FinancialAccount {
  final int? id;
  final String code;
  final String name;
  final AccountType type;
  final int? parentId;
  final bool isParent;
  final double balance;

  FinancialAccount({
    this.id,
    required this.code,
    required this.name,
    required this.type,
    this.parentId,
    this.isParent = false,
    this.balance = 0.0,
  });

  // Create account from database map
  factory FinancialAccount.fromMap(Map<String, dynamic> map) {
    return FinancialAccount(
      id: map['id'],
      code: map['code'],
      name: map['name'],
      type: AccountType.values[map['type']],
      parentId: map['parent_id'],
      isParent: map['is_parent'] == 1,
      balance: map['balance'] is int
          ? (map['balance'] as int).toDouble()
          : (map['balance'] ?? 0.0),
    );
  }

  // Convert account to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'type': type.index,
      'parent_id': parentId,
      'is_parent': isParent ? 1 : 0,
      'balance': balance,
    };
  }

  // Create copy of account with new values
  FinancialAccount copyWith({
    int? id,
    String? code,
    String? name,
    AccountType? type,
    int? parentId,
    bool? isParent,
    double? balance,
  }) {
    return FinancialAccount(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      type: type ?? this.type,
      parentId: parentId ?? this.parentId,
      isParent: isParent ?? this.isParent,
      balance: balance ?? this.balance,
    );
  }

  // Format balance as currency string
  String get formattedBalance {
    return 'Rp ${balance.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},'
    )}';
  }

  // Determine color based on account type (for UI)
  Color getTypeColor() {
    switch (type) {
      case AccountType.asset:
        return Colors.blue;
      case AccountType.liability:
        return Colors.red;
      case AccountType.equity:
        return Colors.green;
      case AccountType.revenue:
        return Colors.purple;
      case AccountType.expense:
        return Colors.orange;
    }
  }

  // Get account type name in Indonesian
  String get typeName {
    switch (type) {
      case AccountType.asset:
        return 'Aset';
      case AccountType.liability:
        return 'Kewajiban';
      case AccountType.equity:
        return 'Ekuitas';
      case AccountType.revenue:
        return 'Pendapatan';
      case AccountType.expense:
        return 'Beban';
    }
  }

  @override
  String toString() {
    return 'FinancialAccount{id: $id, code: $code, name: $name, type: $type, balance: $balance}';
  }
}