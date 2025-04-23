// lib/data/models/outlet.dart
class Outlet {
  final int? id;
  final String name;
  final String address;
  final String? phone;
  
  // Optional fields for display or business logic
  final int? employeeCount;
  final double? totalSales;

  Outlet({
    this.id,
    required this.name,
    required this.address,
    this.phone,
    this.employeeCount,
    this.totalSales,
  });

  factory Outlet.fromMap(Map<String, dynamic> map) {
    return Outlet(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      phone: map['phone'],
      employeeCount: map['employee_count'],
      totalSales: map['total_sales'] != null ? (map['total_sales'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
    };
  }

  Outlet copyWith({
    int? id,
    String? name,
    String? address,
    String? phone,
    int? employeeCount,
    double? totalSales,
  }) {
    return Outlet(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      employeeCount: employeeCount ?? this.employeeCount,
      totalSales: totalSales ?? this.totalSales,
    );
  }

  @override
  String toString() {
    return 'Outlet{id: $id, name: $name, address: $address, phone: $phone}';
  }
}