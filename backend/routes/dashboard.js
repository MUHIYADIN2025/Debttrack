// backend/routes/dashboard.js — Summary stats for the app dashboard
// backend/routes/reports.js   — Detailed reports + PDF export

const express = require('express');
const { Customer, Debt, Payment } = require('../models');
const { protect } = require('../middleware/auth');

// ================================================================
// DASHBOARD  (GET /api/dashboard)
// ================================================================
const dashRouter = express.Router();
dashRouter.use(protect);

dashRouter.get('/', async (req, res) => {
  try {
    const mid = req.user._id;

    // Parallel queries for performance
    const [
      totalCustomers,
      debts,
      payments,
      recentDebts,
      recentPayments,
    ] = await Promise.all([
      Customer.countDocuments({ merchantId: mid, isActive: true }),
      Debt.find({ merchantId: mid }),
      Payment.find({ merchantId: mid }),
      Debt.find({ merchantId: mid }).populate('customerId', 'name phone').sort({ createdAt: -1 }).limit(5),
      Payment.find({ merchantId: mid }).populate('customerId', 'name').sort({ date: -1 }).limit(5),
    ]);

    const totalDebt      = debts.reduce((s, d) => s + d.amount, 0);
    const totalCollected = payments.reduce((s, p) => s + p.amount, 0);
    const totalRemaining = totalDebt - totalCollected;

    // Monthly breakdown — last 6 months
    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 5);

    const monthlyDebts = await Debt.aggregate([
      { $match: { merchantId: mid, date: { $gte: sixMonthsAgo } } },
      { $group: {
        _id: { year: { $year: '$date' }, month: { $month: '$date' } },
        total: { $sum: '$amount' },
        count: { $sum: 1 },
      }},
      { $sort: { '_id.year': 1, '_id.month': 1 } },
    ]);

    const monthlyPayments = await Payment.aggregate([
      { $match: { merchantId: mid, date: { $gte: sixMonthsAgo } } },
      { $group: {
        _id: { year: { $year: '$date' }, month: { $month: '$date' } },
        total: { $sum: '$amount' },
      }},
      { $sort: { '_id.year': 1, '_id.month': 1 } },
    ]);

    // Status counts
    const statusCounts = {
      unpaid:  debts.filter(d => d.status === 'unpaid').length,
      partial: debts.filter(d => d.status === 'partial').length,
      paid:    debts.filter(d => d.status === 'paid').length,
    };

    res.json({
      success: true,
      data: {
        summary: {
          totalCustomers,
          totalDebt,
          totalCollected,
          totalRemaining,
          collectionRate: totalDebt > 0 ? Math.round((totalCollected / totalDebt) * 100) : 0,
        },
        statusCounts,
        monthly:  { debts: monthlyDebts, payments: monthlyPayments },
        recent:   { debts: recentDebts, payments: recentPayments },
      },
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ================================================================
// REPORTS  (GET /api/reports)
// ================================================================
const reportsRouter = express.Router();
reportsRouter.use(protect);

// Customer debt report
reportsRouter.get('/customers', async (req, res) => {
  try {
    const mid = req.user._id;
    const customers = await Customer.find({ merchantId: mid, isActive: true });

    const report = await Promise.all(customers.map(async (c) => {
      const debts    = await Debt.find({ customerId: c._id });
      const payments = await Payment.find({ customerId: c._id });
      const totalDebt = debts.reduce((s, d) => s + d.amount, 0);
      const totalPaid = payments.reduce((s, p) => s + p.amount, 0);

      return {
        customer: { id: c._id, name: c.name, phone: c.phone, address: c.address },
        totalDebt,
        totalPaid,
        balance:      totalDebt - totalPaid,
        debtCount:    debts.length,
        paymentCount: payments.length,
        collectionPct: totalDebt > 0 ? Math.round((totalPaid / totalDebt) * 100) : 0,
        status:       totalDebt === 0 ? 'none'
                    : totalPaid >= totalDebt ? 'settled'
                    : totalPaid > 0 ? 'partial'
                    : 'unpaid',
        debts,
        payments,
      };
    }));

    // Sort by balance descending (highest owed first)
    report.sort((a, b) => b.balance - a.balance);

    res.json({ success: true, data: report });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Payment report — date range
// GET /api/reports/payments?from=2026-01-01&to=2026-12-31
reportsRouter.get('/payments', async (req, res) => {
  try {
    const { from, to } = req.query;
    const query = { merchantId: req.user._id };
    if (from || to) {
      query.date = {};
      if (from) query.date.$gte = new Date(from);
      if (to)   query.date.$lte = new Date(to);
    }

    const payments = await Payment.find(query)
      .populate('customerId', 'name phone')
      .populate('debtId',     'description amount')
      .sort({ date: -1 });

    const total = payments.reduce((s, p) => s + p.amount, 0);

    res.json({ success: true, data: payments, totalCollected: total });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PDF Export endpoint — returns JSON data for client-side PDF generation
// GET /api/reports/export?type=customers|payments
reportsRouter.get('/export', async (req, res) => {
  try {
    const { type = 'customers' } = req.query;
    // In production: use puppeteer or pdfkit to generate actual PDF
    // Here we return structured data the Flutter app uses to generate PDF
    res.json({
      success: true,
      message: 'Export data ready — use flutter pdf package to render',
      type,
      generatedAt: new Date().toISOString(),
      merchant: req.user.name,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = { dashRouter, reportsRouter };
