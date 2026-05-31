// backend/routes/debts.js  +  backend/routes/payments.js
// Combined file — split into separate files in production

// ================================================================
// DEBTS ROUTES  (backend/routes/debts.js)
// ================================================================
const express  = require('express');
const { Debt, Payment, Customer } = require('../models');
const { protect } = require('../middleware/auth');

const debtRouter = express.Router();
debtRouter.use(protect);

// GET /api/debts?customerId=&status=&page=1
debtRouter.get('/', async (req, res) => {
  try {
    const { customerId, status, page = 1, limit = 20 } = req.query;
    const query = { merchantId: req.user._id };
    if (customerId) query.customerId = customerId;
    if (status)     query.status     = status;

    const skip  = (parseInt(page) - 1) * parseInt(limit);
    const debts = await Debt.find(query)
      .populate('customerId', 'name phone')
      .sort({ date: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Debt.countDocuments(query);

    res.json({
      success: true,
      data: debts,
      pagination: { total, page: parseInt(page), pages: Math.ceil(total / limit) },
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/debts/:id
debtRouter.get('/:id', async (req, res) => {
  try {
    const debt = await Debt.findOne({ _id: req.params.id, merchantId: req.user._id })
      .populate('customerId', 'name phone address');
    if (!debt) return res.status(404).json({ success: false, message: 'Debt not found' });

    const payments = await Payment.find({ debtId: debt._id }).sort({ date: -1 });
    res.json({ success: true, data: { ...debt.toObject(), payments } });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/debts
debtRouter.post('/', async (req, res) => {
  try {
    const { customerId, amount, date, description, status } = req.body;

    // Verify customer belongs to this merchant
    const customer = await Customer.findOne({ _id: customerId, merchantId: req.user._id });
    if (!customer) return res.status(404).json({ success: false, message: 'Customer not found' });

    const debt = await Debt.create({
      merchantId: req.user._id,
      customerId,
      amount: parseFloat(amount),
      date: date || new Date(),
      description,
      status: status || 'unpaid',
      balance: parseFloat(amount),
    });

    res.status(201).json({ success: true, message: 'Debt recorded', data: debt });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
});

// PATCH /api/debts/:id
debtRouter.patch('/:id', async (req, res) => {
  try {
    const allowed = ['description', 'date', 'status'];
    const updates = {};
    allowed.forEach(f => { if (req.body[f] !== undefined) updates[f] = req.body[f]; });

    const debt = await Debt.findOneAndUpdate(
      { _id: req.params.id, merchantId: req.user._id },
      updates,
      { new: true }
    );
    if (!debt) return res.status(404).json({ success: false, message: 'Debt not found' });
    res.json({ success: true, data: debt });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
});

// DELETE /api/debts/:id
debtRouter.delete('/:id', async (req, res) => {
  try {
    const debt = await Debt.findOneAndDelete({ _id: req.params.id, merchantId: req.user._id });
    if (!debt) return res.status(404).json({ success: false, message: 'Debt not found' });
    // Also remove related payments
    await Payment.deleteMany({ debtId: req.params.id });
    res.json({ success: true, message: 'Debt deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ================================================================
// PAYMENTS ROUTES  (backend/routes/payments.js)
// ================================================================
const paymentRouter = express.Router();
paymentRouter.use(protect);

// GET /api/payments?customerId=&debtId=
paymentRouter.get('/', async (req, res) => {
  try {
    const { customerId, debtId, page = 1, limit = 20 } = req.query;
    const query = { merchantId: req.user._id };
    if (customerId) query.customerId = customerId;
    if (debtId)     query.debtId     = debtId;

    const skip     = (parseInt(page) - 1) * parseInt(limit);
    const payments = await Payment.find(query)
      .populate('customerId', 'name phone')
      .populate('debtId',     'description amount')
      .sort({ date: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Payment.countDocuments(query);
    const sum   = await Payment.aggregate([
      { $match: { merchantId: req.user._id } },
      { $group: { _id: null, total: { $sum: '$amount' } } },
    ]);

    res.json({
      success: true,
      data: payments,
      totalCollected: sum[0]?.total || 0,
      pagination: { total, page: parseInt(page), pages: Math.ceil(total / limit) },
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/payments  — Record a payment and auto-update debt
paymentRouter.post('/', async (req, res) => {
  try {
    const { customerId, debtId, amount, date, note } = req.body;

    if (!debtId || !amount) {
      return res.status(400).json({ success: false, message: 'debtId and amount required' });
    }

    // Validate debt belongs to merchant
    const debt = await Debt.findOne({ _id: debtId, merchantId: req.user._id });
    if (!debt) return res.status(404).json({ success: false, message: 'Debt not found' });

    const payAmount = parseFloat(amount);

    // Create payment record
    const payment = await Payment.create({
      merchantId: req.user._id,
      customerId: customerId || debt.customerId,
      debtId,
      amount: payAmount,
      date: date || new Date(),
      note,
    });

    // ── Auto-recalculate debt ─────────────────────────────────────
    // Balance formula: Balance = Total Debt - Total Payments
    const allPayments   = await Payment.find({ debtId });
    const totalPaidSoFar = allPayments.reduce((s, p) => s + p.amount, 0);

    debt.amountPaid = totalPaidSoFar;
    debt.balance    = debt.amount - totalPaidSoFar;
    if (debt.balance <= 0) {
      debt.balance = 0;
      debt.status  = 'paid';
    } else if (totalPaidSoFar > 0) {
      debt.status = 'partial';
    }
    await debt.save();

    res.status(201).json({
      success: true,
      message: 'Payment recorded',
      data: payment,
      debt: {
        id:          debt._id,
        status:      debt.status,
        amountPaid:  debt.amountPaid,
        balance:     debt.balance,
      },
    });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
});

// DELETE /api/payments/:id  — Reverse a payment
paymentRouter.delete('/:id', async (req, res) => {
  try {
    const payment = await Payment.findOneAndDelete({ _id: req.params.id, merchantId: req.user._id });
    if (!payment) return res.status(404).json({ success: false, message: 'Payment not found' });

    // Recalculate debt after reversal
    const debt = await Debt.findById(payment.debtId);
    if (debt) {
      const remaining  = await Payment.find({ debtId: debt._id });
      debt.amountPaid  = remaining.reduce((s, p) => s + p.amount, 0);
      debt.balance     = debt.amount - debt.amountPaid;
      debt.status      = debt.balance <= 0 ? 'paid' : debt.amountPaid > 0 ? 'partial' : 'unpaid';
      await debt.save();
    }

    res.json({ success: true, message: 'Payment reversed' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = { debtRouter, paymentRouter };
