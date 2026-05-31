// backend/routes/customers.js
// Full CRUD for customer management

const express = require('express');
const { Customer, Debt, Payment } = require('../models');
const { protect } = require('../middleware/auth');

const router = express.Router();
router.use(protect);

// ── GET All Customers ─────────────────────────────────────────────
// GET /api/customers?search=&page=1&limit=20
router.get('/', async (req, res) => {
  try {
    const { search = '', page = 1, limit = 20 } = req.query;
    const query = { merchantId: req.user._id, isActive: true };

    if (search) {
      query.$or = [
        { name:  { $regex: search, $options: 'i' } },
        { phone: { $regex: search, $options: 'i' } },
      ];
    }

    const skip      = (parseInt(page) - 1) * parseInt(limit);
    const customers = await Customer.find(query).sort({ createdAt: -1 }).skip(skip).limit(parseInt(limit));
    const total     = await Customer.countDocuments(query);

    // Attach balance to each customer
    const enriched = await Promise.all(customers.map(async (c) => {
      const debts    = await Debt.find({ customerId: c._id });
      const payments = await Payment.find({ customerId: c._id });
      const totalDebt = debts.reduce((s, d) => s + d.amount, 0);
      const totalPaid = payments.reduce((s, p) => s + p.amount, 0);
      return { ...c.toObject(), totalDebt, totalPaid, balance: totalDebt - totalPaid };
    }));

    res.json({
      success: true,
      data: enriched,
      pagination: { total, page: parseInt(page), limit: parseInt(limit), pages: Math.ceil(total / limit) },
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ── GET Single Customer ───────────────────────────────────────────
// GET /api/customers/:id
router.get('/:id', async (req, res) => {
  try {
    const customer = await Customer.findOne({ _id: req.params.id, merchantId: req.user._id });
    if (!customer) return res.status(404).json({ success: false, message: 'Customer not found' });

    const debts    = await Debt.find({ customerId: customer._id }).sort({ date: -1 });
    const payments = await Payment.find({ customerId: customer._id }).sort({ date: -1 });
    const totalDebt = debts.reduce((s, d) => s + d.amount, 0);
    const totalPaid = payments.reduce((s, p) => s + p.amount, 0);

    res.json({
      success: true,
      data: {
        ...customer.toObject(),
        totalDebt,
        totalPaid,
        balance: totalDebt - totalPaid,
        debts,
        recentPayments: payments.slice(0, 10),
      },
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ── CREATE Customer ───────────────────────────────────────────────
// POST /api/customers
router.post('/', async (req, res) => {
  try {
    const { name, phone, address, notes } = req.body;
    const customer = await Customer.create({ merchantId: req.user._id, name, phone, address, notes });
    res.status(201).json({ success: true, message: 'Customer added', data: customer });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
});

// ── UPDATE Customer ───────────────────────────────────────────────
// PATCH /api/customers/:id
router.patch('/:id', async (req, res) => {
  try {
    const allowed = ['name', 'phone', 'address', 'notes'];
    const updates = {};
    allowed.forEach(f => { if (req.body[f] !== undefined) updates[f] = req.body[f]; });

    const customer = await Customer.findOneAndUpdate(
      { _id: req.params.id, merchantId: req.user._id },
      updates,
      { new: true, runValidators: true }
    );

    if (!customer) return res.status(404).json({ success: false, message: 'Customer not found' });
    res.json({ success: true, message: 'Customer updated', data: customer });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
});

// ── DELETE Customer (soft delete) ─────────────────────────────────
// DELETE /api/customers/:id
router.delete('/:id', async (req, res) => {
  try {
    const customer = await Customer.findOneAndUpdate(
      { _id: req.params.id, merchantId: req.user._id },
      { isActive: false },
      { new: true }
    );
    if (!customer) return res.status(404).json({ success: false, message: 'Customer not found' });
    res.json({ success: true, message: 'Customer deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
