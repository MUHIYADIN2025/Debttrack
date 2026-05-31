// lib/widgets/common_widgets.dart
// Reusable UI components used across all screens

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/helpers.dart';

// ── Customer Avatar ────────────────────────────────────────────────
class CustomerAvatar extends StatelessWidget {
  final String name;
  final double size;

  const CustomerAvatar({super.key, required this.name, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final color = avatarColor(name);
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.2)),
      alignment: Alignment.center,
      child: Text(
        getInitials(name),
        style: TextStyle(color: color, fontSize: size * 0.33, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Debt Status Badge ─────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final DebtStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: statusBgColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusLabel(status),
        style: TextStyle(color: statusColor(status), fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ]),
      ),
    );
  }
}

// ── Progress Card ─────────────────────────────────────────────────
class ProgressCard extends StatelessWidget {
  final String label;
  final double value;      // 0.0 – 1.0
  final String leftLabel;
  final String rightLabel;

  const ProgressCard({
    super.key,
    required this.label,
    required this.value,
    required this.leftLabel,
    required this.rightLabel,
  });

  @override
  Widget build(BuildContext context) {
    final pct     = (value.clamp(0.0, 1.0) * 100).toInt();
    final barColor = pct > 70 ? const Color(0xFF22C55E) : pct > 40 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('$pct%', style: TextStyle(color: barColor, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFF252A3A),
              valueColor: AlwaysStoppedAnimation(barColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(leftLabel,  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(rightLabel, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
        ]),
      ),
    );
  }
}

// ── Customer List Tile ────────────────────────────────────────────
class CustomerTile extends StatelessWidget {
  final Customer customer;
  final VoidCallback? onTap;

  const CustomerTile({super.key, required this.customer, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bal = customer.balance;
    return ListTile(
      leading: CustomerAvatar(name: customer.name),
      title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(customer.phone, style: const TextStyle(fontSize: 13)),
      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(
          formatCurrency(bal),
          style: TextStyle(
            color: bal > 0 ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
            fontWeight: FontWeight.w600, fontSize: 13,
          ),
        ),
        Text(bal > 0 ? 'owes' : 'settled', style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ]),
      onTap: onTap,
    );
  }
}

// ── Debt List Tile ────────────────────────────────────────────────
class DebtTile extends StatelessWidget {
  final Debt debt;
  final VoidCallback? onTap;

  const DebtTile({super.key, required this.debt, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(children: [
        Expanded(child: Text(debt.description, style: const TextStyle(fontWeight: FontWeight.w500))),
        StatusBadge(status: debt.status),
      ]),
      subtitle: Text(formatDate(debt.date), style: const TextStyle(fontSize: 12)),
      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(formatCurrency(debt.amount), style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700, fontSize: 13)),
        Text('Bal: ${formatCurrency(debt.balance)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ]),
      onTap: onTap,
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 56, color: Colors.grey.shade600),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!, style: const TextStyle(fontSize: 13, color: Colors.grey), textAlign: TextAlign.center),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ]),
      ),
    );
  }
}

// ── Loading Overlay ───────────────────────────────────────────────
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({super.key, required this.isLoading, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      child,
      if (isLoading)
        Container(
          color: Colors.black45,
          child: const Center(child: CircularProgressIndicator()),
        ),
    ]);
  }
}

// ── Section Header ────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title.toUpperCase(),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: 0.5)),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!, style: const TextStyle(fontSize: 12, color: Color(0xFF4F8EF7))),
          ),
      ]),
    );
  }
}

// ── Info Row (for detail screens) ─────────────────────────────────
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoRow({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14)),
        ]),
      ]),
    );
  }
}
