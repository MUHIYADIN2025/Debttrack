// lib/utils/helpers.dart
// Shared utility functions used across the app

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

// ── Currency ──────────────────────────────────────────────────────
final _numFmt = NumberFormat('#,##0', 'en_US');

String formatCurrency(double amount) {
  return '${_numFmt.format(amount.round())} SOS';
}

String formatCurrencyShort(double amount) {
  if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M SOS';
  if (amount >= 1000)    return '${(amount / 1000).toStringAsFixed(1)}K SOS';
  return '${amount.round()} SOS';
}

// ── Dates ─────────────────────────────────────────────────────────
String formatDate(DateTime date) => DateFormat('dd MMM yyyy').format(date);
String formatDateShort(DateTime date) => DateFormat('dd/MM/yy').format(date);
String formatDateTime(DateTime date) => DateFormat('dd MMM yyyy · HH:mm').format(date);
String formatMonthYear(DateTime date) => DateFormat('MMMM yyyy').format(date);

String timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inDays > 30)  return formatDate(date);
  if (diff.inDays > 0)   return '${diff.inDays}d ago';
  if (diff.inHours > 0)  return '${diff.inHours}h ago';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
  return 'Just now';
}

// ── Debt Status ───────────────────────────────────────────────────
Color statusColor(DebtStatus status) {
  switch (status) {
    case DebtStatus.paid:    return const Color(0xFF22C55E);
    case DebtStatus.partial: return const Color(0xFFF59E0B);
    case DebtStatus.unpaid:  return const Color(0xFFEF4444);
  }
}

Color statusBgColor(DebtStatus status) => statusColor(status).withOpacity(0.15);

String statusLabel(DebtStatus status) {
  switch (status) {
    case DebtStatus.paid:    return 'Paid';
    case DebtStatus.partial: return 'Partial';
    case DebtStatus.unpaid:  return 'Unpaid';
  }
}

IconData statusIcon(DebtStatus status) {
  switch (status) {
    case DebtStatus.paid:    return Icons.check_circle_outline;
    case DebtStatus.partial: return Icons.timelapse_outlined;
    case DebtStatus.unpaid:  return Icons.cancel_outlined;
  }
}

// ── Avatars ───────────────────────────────────────────────────────
String getInitials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  if (parts[0].length >= 2) return parts[0].substring(0, 2).toUpperCase();
  return parts[0][0].toUpperCase();
}

Color avatarColor(String name) {
  final colors = [
    const Color(0xFF4F8EF7),
    const Color(0xFFF59E0B),
    const Color(0xFF22C55E),
    const Color(0xFFA78BFA),
    const Color(0xFFEF4444),
    const Color(0xFF06B6D4),
  ];
  final index = name.codeUnits.fold<int>(0, (s, c) => s + c) % colors.length;
  return colors[index];
}

// ── Validation ────────────────────────────────────────────────────
String? validateRequired(String? value, [String field = 'This field']) {
  if (value == null || value.trim().isEmpty) return '$field is required';
  return null;
}

String? validateEmail(String? value) {
  if (value == null || value.isEmpty) return 'Email is required';
  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) return 'Enter a valid email';
  return null;
}

String? validatePhone(String? value) {
  if (value == null || value.isEmpty) return 'Phone is required';
  if (value.length < 7) return 'Enter a valid phone number';
  return null;
}

String? validateAmount(String? value) {
  if (value == null || value.isEmpty) return 'Amount is required';
  final n = double.tryParse(value);
  if (n == null) return 'Enter a valid number';
  if (n <= 0)    return 'Amount must be greater than 0';
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Password is required';
  if (value.length < 6) return 'Password must be at least 6 characters';
  return null;
}

// ── Snackbars ─────────────────────────────────────────────────────
void showSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
      const SizedBox(width: 8),
      Text(message),
    ]),
    backgroundColor: const Color(0xFF22C55E),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    duration: const Duration(seconds: 2),
  ));
}

void showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      const Icon(Icons.error_outline, color: Colors.white, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(message)),
    ]),
    backgroundColor: const Color(0xFFEF4444),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ));
}

// ── Confirmation Dialog ───────────────────────────────────────────
Future<bool> showConfirmDialog(BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Delete',
  Color? confirmColor,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E2230),
      title: Text(title),
      content: Text(message, style: const TextStyle(color: Colors.grey)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: confirmColor ?? const Color(0xFFEF4444)),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return result ?? false;
}
