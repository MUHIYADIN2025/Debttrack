// ================================================================
// DebtTrack Flutter — All App Screens
// File: lib/screens/screens.dart
// ================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

// ── Currency Formatter ────────────────────────────────────────────
final _currencyFmt = NumberFormat('#,##0', 'en_US');
String fmtCurrency(double amount) => '${_currencyFmt.format(amount)} SOS';

// ── Status Colors ─────────────────────────────────────────────────
Color statusColor(DebtStatus s) {
  switch (s) {
    case DebtStatus.paid:    return const Color(0xFF22C55E);
    case DebtStatus.partial: return const Color(0xFFF59E0B);
    case DebtStatus.unpaid:  return const Color(0xFFEF4444);
  }
}

// ================================================================
// LOGIN SCREEN
// ================================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController(text: 'admin@debttrack.com');
  final _passCtrl  = TextEditingController(text: 'admin123');
  bool _isRegister = false;
  bool _loading    = false;
  bool _obscure    = true;

  final _nameCtrl    = TextEditingController();
  final _regPassCtrl = TextEditingController();
  String _role = 'Merchant';

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthService>();
      final api  = context.read<ApiService>();
      if (_isRegister) {
        await auth.register({
          'name': _nameCtrl.text, 'email': _emailCtrl.text,
          'password': _regPassCtrl.text, 'role': _role,
        }, api);
      } else {
        await auth.login(_emailCtrl.text, _passCtrl.text, api);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Logo
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F8EF7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              const Text('DebtTrack', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
              const Text('Smart debt management for merchants', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              // Tabs
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF181B24),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(children: [
                  _tabBtn('Sign In', !_isRegister, () => setState(() => _isRegister = false)),
                  _tabBtn('Register', _isRegister, () => setState(() => _isRegister = true)),
                ]),
              ),
              const SizedBox(height: 24),
              if (_isRegister) ...[
                _input(_nameCtrl, 'Full Name', Icons.person_outline),
                const SizedBox(height: 12),
              ],
              _input(_emailCtrl, 'Email', Icons.email_outlined),
              const SizedBox(height: 12),
              _input(
                _isRegister ? _regPassCtrl : _passCtrl,
                'Password', Icons.lock_outline,
                obscure: _obscure,
                suffix: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              if (_isRegister) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: const InputDecoration(labelText: 'Role', prefixIcon: Icon(Icons.badge_outlined)),
                  items: ['Merchant', 'Admin'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setState(() => _role = v!),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) : Text(_isRegister ? 'Create Account' : 'Sign In'),
                ),
              ),
              if (!_isRegister) ...[
                const SizedBox(height: 16),
                const Text('Demo: admin@debttrack.com / admin123', style: TextStyle(fontSize: 12, color: Colors.grey54)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabBtn(String label, bool active, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1E2230) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w500, color: active ? Colors.white : Colors.grey)),
      ),
    ),
  );

  Widget _input(TextEditingController ctrl, String label, IconData icon, {bool obscure = false, Widget? suffix}) =>
    TextFormField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), suffixIcon: suffix),
    );
}

// ================================================================
// DASHBOARD SCREEN
// ================================================================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardStats? _stats;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final stats = await context.read<ApiService>().getDashboard();
      if (mounted) setState(() { _stats = stats; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().user;
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Good morning 👋', style: const TextStyle(fontSize: 18)),
          Text(user?.name ?? '', style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_stats != null) ...[
                    GridView.count(
                      crossAxisCount: 2, shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12, mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        _statCard('Customers',   _stats!.totalCustomers.toString(), const Color(0xFF4F8EF7), Icons.people),
                        _statCard('Total Debt',  fmtCurrency(_stats!.totalDebt),    const Color(0xFFEF4444), Icons.receipt_long),
                        _statCard('Collected',   fmtCurrency(_stats!.totalCollected), const Color(0xFF22C55E), Icons.check_circle_outline),
                        _statCard('Remaining',   fmtCurrency(_stats!.totalRemaining), const Color(0xFFF59E0B), Icons.schedule),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Collection rate
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              const Text('Collection Rate', style: TextStyle(fontWeight: FontWeight.w500)),
                              Text('${_stats!.collectionRate}%', style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.w600)),
                            ]),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _stats!.collectionRate / 100,
                                backgroundColor: const Color(0xFF252A3A),
                                valueColor: const AlwaysStoppedAnimation(Color(0xFF22C55E)),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
      ]),
    ),
  );
}

// ================================================================
// CUSTOMERS SCREEN
// ================================================================
class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});
  @override State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<Customer> _customers = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load([String? search]) async {
    setState(() => _loading = true);
    try {
      final list = await context.read<ApiService>().getCustomers(search: search);
      if (mounted) setState(() { _customers = list; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Customers')),
    body: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: TextField(
          controller: _searchCtrl,
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search customers...'),
          onChanged: (v) => _load(v.isEmpty ? null : v),
        ),
      ),
      Expanded(
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _customers.isEmpty
                ? const Center(child: Text('No customers yet'))
                : ListView.builder(
                    itemCount: _customers.length,
                    itemBuilder: (ctx, i) {
                      final c = _customers[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF4F8EF7).withOpacity(0.2),
                          child: Text(c.initials, style: const TextStyle(color: Color(0xFF4F8EF7), fontWeight: FontWeight.w600)),
                        ),
                        title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text(c.phone),
                        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(fmtCurrency(c.balance), style: TextStyle(color: c.balance > 0 ? const Color(0xFFEF4444) : const Color(0xFF22C55E), fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(c.balance > 0 ? 'owes' : 'settled', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ]),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerDetailScreen(customer: c))).then((_) => _load()),
                      );
                    },
                  ),
            ),
      ),
    ]),
    floatingActionButton: FloatingActionButton(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCustomerScreen())).then((_) => _load()),
      child: const Icon(Icons.add),
    ),
  );
}

// ================================================================
// ADD CUSTOMER SCREEN
// ================================================================
class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});
  @override State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl   = TextEditingController();
  bool _loading = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await context.read<ApiService>().createCustomer({
        'name': _nameCtrl.text, 'phone': _phoneCtrl.text,
        'address': _addressCtrl.text, 'notes': _notesCtrl.text,
      });
      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer added!'))); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Add Customer')),
    body: Form(
      key: _formKey,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        TextFormField(controller: _nameCtrl,    decoration: const InputDecoration(labelText: 'Full Name *', prefixIcon: Icon(Icons.person_outline)), validator: (v) => v!.isEmpty ? 'Required' : null),
        const SizedBox(height: 12),
        TextFormField(controller: _phoneCtrl,   decoration: const InputDecoration(labelText: 'Phone *', prefixIcon: Icon(Icons.phone_outlined)), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Required' : null),
        const SizedBox(height: 12),
        TextFormField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_outlined))),
        const SizedBox(height: 12),
        TextFormField(controller: _notesCtrl,   decoration: const InputDecoration(labelText: 'Notes', prefixIcon: Icon(Icons.note_outlined)), maxLines: 3),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _loading ? null : _save, child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Add Customer')),
      ]),
    ),
  );
}

// ================================================================
// CUSTOMER DETAIL SCREEN
// ================================================================
class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;
  const CustomerDetailScreen({super.key, required this.customer});
  @override State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Debt>    _debts    = [];
  List<Payment> _payments = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 3, vsync: this); _load(); }

  Future<void> _load() async {
    try {
      final debts    = await context.read<ApiService>().getDebts(customerId: widget.customer.id);
      final payments = await context.read<ApiService>().getPayments(customerId: widget.customer.id);
      if (mounted) setState(() { _debts = debts; _payments = payments; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    final pct = c.totalDebt > 0 ? c.totalPaid / c.totalDebt : 0.0;
    return Scaffold(
      appBar: AppBar(title: Text(c.name)),
      body: Column(children: [
        // Hero stats
        Container(
          color: const Color(0xFF181B24),
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              _miniStat('Total Debt',  fmtCurrency(c.totalDebt),      const Color(0xFFEF4444)),
              const SizedBox(width: 8),
              _miniStat('Paid',        fmtCurrency(c.totalPaid),       const Color(0xFF22C55E)),
              const SizedBox(width: 8),
              _miniStat('Balance',     fmtCurrency(c.balance),          const Color(0xFFF59E0B)),
            ]),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Collection progress', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('${(pct * 100).toInt()}%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct, minHeight: 6,
                backgroundColor: const Color(0xFF252A3A),
                valueColor: AlwaysStoppedAnimation(pct > 0.7 ? const Color(0xFF22C55E) : pct > 0.4 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
              ),
            ),
          ]),
        ),
        TabBar(controller: _tabCtrl, tabs: const [Tab(text: 'Debts'), Tab(text: 'Payments'), Tab(text: 'Info')]),
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(controller: _tabCtrl, children: [
                // DEBTS TAB
                _debts.isEmpty
                  ? const Center(child: Text('No debts recorded'))
                  : ListView.builder(
                      itemCount: _debts.length,
                      itemBuilder: (ctx, i) {
                        final d = _debts[i];
                        return ListTile(
                          title: Text(d.description),
                          subtitle: Text(DateFormat('dd MMM yyyy').format(d.date)),
                          trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text(fmtCurrency(d.amount), style: const TextStyle(fontWeight: FontWeight.w600)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: statusColor(d.status).withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                              child: Text(d.statusLabel, style: TextStyle(color: statusColor(d.status), fontSize: 11)),
                            ),
                          ]),
                        );
                      },
                    ),
                // PAYMENTS TAB
                _payments.isEmpty
                  ? const Center(child: Text('No payments yet'))
                  : ListView.builder(
                      itemCount: _payments.length,
                      itemBuilder: (ctx, i) {
                        final p = _payments[i];
                        return ListTile(
                          leading: const CircleAvatar(backgroundColor: Color(0xFF22C55E), child: Icon(Icons.check, color: Colors.white, size: 18)),
                          title: Text(fmtCurrency(p.amount), style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.w600)),
                          subtitle: Text('${p.debtDescription ?? ''} · ${DateFormat('dd MMM yyyy').format(p.date)}'),
                        );
                      },
                    ),
                // INFO TAB
                ListView(padding: const EdgeInsets.all(16), children: [
                  _infoRow('Phone',   c.phone,             Icons.phone_outlined),
                  _infoRow('Address', c.address ?? '—',    Icons.location_on_outlined),
                  _infoRow('Notes',   c.notes   ?? '—',    Icons.note_outlined),
                ]),
              ]),
        ),
        // Action buttons
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(child: ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Debt'),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddDebtScreen(customerId: c.id))).then((_) => _load()),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton.icon(
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: const Text('Record Pay'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E)),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecordPaymentScreen(customerId: c.id, debts: _debts))).then((_) => _load()),
              )),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _miniStat(String label, String val, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFF252A3A), borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color), overflow: TextOverflow.ellipsis),
      ]),
    ),
  );

  Widget _infoRow(String label, String value, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(children: [
      Icon(icon, color: Colors.grey, size: 20),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 14)),
      ]),
    ]),
  );
}

// ================================================================
// ADD DEBT SCREEN
// ================================================================
class AddDebtScreen extends StatefulWidget {
  final String customerId;
  const AddDebtScreen({super.key, required this.customerId});
  @override State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _amountCtrl = TextEditingController();
  final _descCtrl   = TextEditingController();
  DateTime _date = DateTime.now();
  String _status = 'unpaid';
  bool _loading = false;

  Future<void> _save() async {
    if (_amountCtrl.text.isEmpty || _descCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill all required fields')));
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<ApiService>().createDebt({
        'customerId': widget.customerId,
        'amount': double.parse(_amountCtrl.text),
        'date': _date.toIso8601String(),
        'description': _descCtrl.text,
        'status': _status,
      });
      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debt recorded!'))); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Add New Debt')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      TextFormField(controller: _amountCtrl, decoration: const InputDecoration(labelText: 'Amount (SOS) *', prefixIcon: Icon(Icons.attach_money)), keyboardType: TextInputType.number),
      const SizedBox(height: 12),
      TextFormField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description *', prefixIcon: Icon(Icons.description_outlined))),
      const SizedBox(height: 12),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.calendar_today_outlined),
        title: const Text('Date'),
        subtitle: Text(DateFormat('dd MMM yyyy').format(_date)),
        onTap: () async {
          final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2030));
          if (d != null) setState(() => _date = d);
        },
      ),
      const Divider(),
      DropdownButtonFormField<String>(
        value: _status,
        decoration: const InputDecoration(labelText: 'Status', prefixIcon: Icon(Icons.flag_outlined)),
        items: [
          DropdownMenuItem(value: 'unpaid',  child: const Text('Unpaid')),
          DropdownMenuItem(value: 'partial', child: const Text('Partial')),
          DropdownMenuItem(value: 'paid',    child: const Text('Paid')),
        ],
        onChanged: (v) => setState(() => _status = v!),
      ),
      const SizedBox(height: 24),
      ElevatedButton(onPressed: _loading ? null : _save, child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Add Debt')),
    ]),
  );
}

// ================================================================
// RECORD PAYMENT SCREEN
// ================================================================
class RecordPaymentScreen extends StatefulWidget {
  final String customerId;
  final List<Debt> debts;
  const RecordPaymentScreen({super.key, required this.customerId, required this.debts});
  @override State<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends State<RecordPaymentScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl   = TextEditingController();
  Debt? _selectedDebt;
  DateTime _date = DateTime.now();
  bool _loading = false;

  @override
  void initState() { super.initState(); if (widget.debts.isNotEmpty) _selectedDebt = widget.debts.first; }

  Future<void> _save() async {
    if (_selectedDebt == null || _amountCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select debt and enter amount')));
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<ApiService>().recordPayment({
        'customerId': widget.customerId,
        'debtId': _selectedDebt!.id,
        'amount': double.parse(_amountCtrl.text),
        'date': _date.toIso8601String(),
        'note': _noteCtrl.text,
      });
      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment recorded!'))); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Record Payment')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      DropdownButtonFormField<Debt>(
        value: _selectedDebt,
        decoration: const InputDecoration(labelText: 'Select Debt *', prefixIcon: Icon(Icons.receipt_long_outlined)),
        items: widget.debts.map((d) => DropdownMenuItem(value: d, child: Text('${d.description} — ${fmtCurrency(d.balance)}'))).toList(),
        onChanged: (v) => setState(() => _selectedDebt = v),
      ),
      const SizedBox(height: 12),
      if (_selectedDebt != null) ...[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF252A3A), borderRadius: BorderRadius.circular(10)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Outstanding balance', style: TextStyle(color: Colors.grey, fontSize: 13)),
            Text(fmtCurrency(_selectedDebt!.balance), style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(height: 12),
      ],
      TextFormField(controller: _amountCtrl, decoration: const InputDecoration(labelText: 'Amount Paid (SOS) *', prefixIcon: Icon(Icons.attach_money)), keyboardType: TextInputType.number),
      const SizedBox(height: 12),
      TextFormField(controller: _noteCtrl,   decoration: const InputDecoration(labelText: 'Note', prefixIcon: Icon(Icons.note_outlined))),
      const SizedBox(height: 12),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.calendar_today_outlined),
        title: const Text('Payment Date'),
        subtitle: Text(DateFormat('dd MMM yyyy').format(_date)),
        onTap: () async {
          final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2030));
          if (d != null) setState(() => _date = d);
        },
      ),
      const SizedBox(height: 24),
      ElevatedButton(onPressed: _loading ? null : _save, child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Record Payment')),
    ]),
  );
}

// ================================================================
// DEBTS SCREEN (all debts)
// ================================================================
class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});
  @override State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  List<Debt> _debts = [];
  bool _loading = true;
  String? _filter;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load([String? status]) async {
    setState(() { _loading = true; _filter = status; });
    try {
      final list = await context.read<ApiService>().getDebts(status: status);
      if (mounted) setState(() { _debts = list; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Debts')),
    body: Column(children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          for (final s in [null, 'unpaid', 'partial', 'paid'])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(s == null ? 'All' : s[0].toUpperCase() + s.substring(1)),
                selected: _filter == s,
                onSelected: (_) => _load(s),
              ),
            ),
        ]),
      ),
      Expanded(
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _debts.isEmpty
            ? const Center(child: Text('No debts found'))
            : ListView.builder(
                itemCount: _debts.length,
                itemBuilder: (ctx, i) {
                  final d = _debts[i];
                  return ListTile(
                    title: Text(d.customerName ?? 'Customer'),
                    subtitle: Text('${d.description} · ${DateFormat('dd MMM yyyy').format(d.date)}'),
                    trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(fmtCurrency(d.amount), style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: statusColor(d.status).withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                        child: Text(d.statusLabel, style: TextStyle(color: statusColor(d.status), fontSize: 11)),
                      ),
                    ]),
                  );
                },
              ),
      ),
    ]),
    floatingActionButton: FloatingActionButton(
      onPressed: () {},
      child: const Icon(Icons.add),
    ),
  );
}

// ================================================================
// PAYMENTS SCREEN (all payments)
// ================================================================
class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});
  @override State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<Payment> _payments = [];
  bool _loading = true;
  double _total = 0;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final list = await context.read<ApiService>().getPayments();
      if (mounted) setState(() { _payments = list; _total = list.fold(0, (s, p) => s + p.amount); _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Payments')),
    body: Column(children: [
      Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF16A34A)]),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Total Collected', style: TextStyle(color: Colors.white70, fontSize: 13)),
            SizedBox(height: 4),
          ]),
          Text(fmtCurrency(_total), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        ]),
      ),
      Expanded(
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _payments.isEmpty
                ? const Center(child: Text('No payments yet'))
                : ListView.builder(
                    itemCount: _payments.length,
                    itemBuilder: (ctx, i) {
                      final p = _payments[i];
                      return ListTile(
                        leading: const CircleAvatar(backgroundColor: Color(0xFF22C55E), child: Icon(Icons.check, color: Colors.white, size: 18)),
                        title: Text(p.customerName ?? 'Customer'),
                        subtitle: Text('${p.debtDescription ?? ''} · ${DateFormat('dd MMM yyyy').format(p.date)}'),
                        trailing: Text('+${fmtCurrency(p.amount)}', style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.w700, fontSize: 14)),
                      );
                    },
                  ),
            ),
      ),
    ]),
  );
}

// ================================================================
// REPORTS SCREEN
// ================================================================
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Map<String, dynamic>> _report = [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await context.read<ApiService>().getCustomerReport();
      if (mounted) setState(() { _report = data; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Reports'),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
          label: const Text('Export PDF'),
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating PDF report...'))),
        ),
      ],
    ),
    body: _loading
      ? const Center(child: CircularProgressIndicator())
      : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _report.length,
          itemBuilder: (ctx, i) {
            final r  = _report[i];
            final c  = r['customer'] as Map;
            final pct = (r['collectionPct'] as num).toDouble();
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(c['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const Spacer(),
                    Text(fmtCurrency((r['balance'] as num).toDouble()), style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    _mini('Debt',    fmtCurrency((r['totalDebt'] as num).toDouble())),
                    _mini('Paid',    fmtCurrency((r['totalPaid'] as num).toDouble())),
                    _mini('${pct.toInt()}%', 'collected'),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100, minHeight: 5,
                      backgroundColor: const Color(0xFF252A3A),
                      valueColor: AlwaysStoppedAnimation(pct > 70 ? const Color(0xFF22C55E) : pct > 40 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
                    ),
                  ),
                ]),
              ),
            );
          },
        ),
  );

  Widget _mini(String top, String bot) => Expanded(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(top, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      Text(bot, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
    ]),
  );
}
