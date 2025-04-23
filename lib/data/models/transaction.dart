// lib/data/models/transaction.dart
import 'package:flutter/foundation.dart';
import 'transaction_item.dart';

class Transaction {
  final int? id;
  final String date;
  final double total;
  final double subtotal;
  final int? outletId;
  final String? paymentMethod;
  final double? cashAmount;
  final double? changeAmount;
  final List<TransactionItem>? items;
  final String? outletName; // For display purposes

  Transaction({
    this.id,
    required this.date,
    required this.total,
    required this.subtotal,
    this.outletId,
    this.paymentMethod,
    this.cashAmount,
    this.changeAmount,
    this.items,
    this.outletName,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      date: map['date'],
      subtotal: map['subtotal'] ?? 0.0,
      total: map['total'] ?? 0.0,
      outletId: map['outlet_id'],
      paymentMethod: map['payment_method'],
      cashAmount: map['cash_amount'],
      changeAmount: map['change_amount'],
      outletName: map['outlet_name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'subtotal': subtotal,
      'total': total,
      'outlet_id': outletId,
      'payment_method': paymentMethod,
      'cash_amount': cashAmount,
      'change_amount': changeAmount,
    };
  }

  Transaction copyWith({
    int? id,
    String? date,
    double? total,
    double? subtotal,
    int? outletId,
    String? paymentMethod,
    double? cashAmount,
    double? changeAmount,
    List<TransactionItem>? items,
    String? outletName,
  }) {
    return Transaction(
      id: id ?? this.id,
      date: date ?? this.date,
      total: total ?? this.total,
      subtotal: subtotal ?? this.subtotal,
      outletId: outletId ?? this.outletId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cashAmount: cashAmount ?? this.cashAmount,
      changeAmount: changeAmount ?? this.changeAmount,
      items: items ?? this.items,
      outletName: outletName ?? this.outletName,
    );
  }

  @override
  String toString() {
    return 'Transaction{id: $id, date: $date, total: $total, subtotal: $subtotal, outletId: $outletId, paymentMethod: $paymentMethod, cashAmount: $cashAmount, changeAmount: $changeAmount, items: $items, outletName: $outletName}';
  }
}