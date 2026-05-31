// ================================================================
// DebtTrack Flutter — Data Models
// File: lib/models/models.dart
// ================================================================

// ── User Model ────────────────────────────────────────────────────
class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? businessName;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.businessName,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id:           json['_id'] ?? json['id'],
    name:         json['name'],
    email:        json['email'],
    role:         json['role'],
    phone:        json['phone'],
    businessName: json['businessName'],
  );

  Map<String, dynamic> toJson() => {
    'name': name, 'email': email, 'role': role,
    'phone': phone, 'businessName': businessName,
  };
}

// ── Customer Model ────────────────────────────────────────────────
class Customer {
  final String id;
  final String name;
  final String phone;
  final String? address;
  final String? notes;
  final double totalDebt;
  final double totalPaid;
  final double balance;
  final DateTime createdAt;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.address,
    this.notes,
    this.totalDebt = 0,
    this.totalPaid = 0,
    this.balance = 0,
    required this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id:        json['_id'] ?? json['id'],
    name:      json['name'],
    phone:     json['phone'],
    address:   json['address'],
    notes:     json['notes'],
    totalDebt: (json['totalDebt'] ?? 0).toDouble(),
    totalPaid: (json['totalPaid'] ?? 0).toDouble(),
    balance:   (json['balance']   ?? 0).toDouble(),
    createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
  );

  String get initials => name.split(' ').take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
}

// ── Debt Model ────────────────────────────────────────────────────
enum DebtStatus { unpaid, partial, paid }

class Debt {
  final String id;
  final String customerId;
  final String? customerName;
  final double amount;
  final double amountPaid;
  final double balance;
  final DateTime date;
  final String description;
  final DebtStatus status;
  final DateTime createdAt;

  const Debt({
    required this.id,
    required this.customerId,
    this.customerName,
    required this.amount,
    this.amountPaid = 0,
    required this.balance,
    required this.date,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory Debt.fromJson(Map<String, dynamic> json) {
    final cust = json['customerId'];
    return Debt(
      id:           json['_id'] ?? json['id'],
      customerId:   cust is Map ? cust['_id'] : cust.toString(),
      customerName: cust is Map ? cust['name'] : null,
      amount:       (json['amount']     ?? 0).toDouble(),
      amountPaid:   (json['amountPaid'] ?? 0).toDouble(),
      balance:      (json['balance']    ?? json['amount'] ?? 0).toDouble(),
      date:         DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      description:  json['description'] ?? '',
      status:       DebtStatus.values.firstWhere(
        (s) => s.name == (json['status'] ?? 'unpaid'),
        orElse: () => DebtStatus.unpaid,
      ),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  String get statusLabel => status.name[0].toUpperCase() + status.name.substring(1);
}

// ── Payment Model ─────────────────────────────────────────────────
class Payment {
  final String id;
  final String customerId;
  final String? customerName;
  final String debtId;
  final String? debtDescription;
  final double amount;
  final DateTime date;
  final String? note;

  const Payment({
    required this.id,
    required this.customerId,
    this.customerName,
    required this.debtId,
    this.debtDescription,
    required this.amount,
    required this.date,
    this.note,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    final cust = json['customerId'];
    final debt = json['debtId'];
    return Payment(
      id:              json['_id'] ?? json['id'],
      customerId:      cust is Map ? cust['_id'] : cust.toString(),
      customerName:    cust is Map ? cust['name'] : null,
      debtId:          debt is Map ? debt['_id'] : debt.toString(),
      debtDescription: debt is Map ? debt['description'] : null,
      amount:          (json['amount'] ?? 0).toDouble(),
      date:            DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      note:            json['note'],
    );
  }
}

// ── Dashboard Stats ───────────────────────────────────────────────
class DashboardStats {
  final int totalCustomers;
  final double totalDebt;
  final double totalCollected;
  final double totalRemaining;
  final int collectionRate;
  final Map<String, int> statusCounts;

  const DashboardStats({
    required this.totalCustomers,
    required this.totalDebt,
    required this.totalCollected,
    required this.totalRemaining,
    required this.collectionRate,
    required this.statusCounts,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final s = json['summary'] ?? {};
    return DashboardStats(
      totalCustomers:  s['totalCustomers'] ?? 0,
      totalDebt:       (s['totalDebt']       ?? 0).toDouble(),
      totalCollected:  (s['totalCollected']   ?? 0).toDouble(),
      totalRemaining:  (s['totalRemaining']   ?? 0).toDouble(),
      collectionRate:  s['collectionRate']    ?? 0,
      statusCounts:    Map<String, int>.from(json['statusCounts'] ?? {}),
    );
  }
}
