// ================================================================
// DebtTrack — MongoDB Database Schemas
// File: backend/models/index.js
// ================================================================

const mongoose = require('mongoose');
const bcrypt   = require('bcryptjs');

// ── USER SCHEMA ─────────────────────────────────────────────────
const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Name is required'],
    trim: true,
    maxlength: 100,
  },
  email: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    lowercase: true,
    trim: true,
    match: [/^\S+@\S+\.\S+$/, 'Invalid email format'],
  },
  password: {
    type: String,
    required: [true, 'Password is required'],
    minlength: 6,
    select: false,                  // never returned in queries by default
  },
  role: {
    type: String,
    enum: ['Admin', 'Merchant'],
    default: 'Merchant',
  },
  phone: { type: String, trim: true },
  businessName: { type: String, trim: true },
  isActive: { type: Boolean, default: true },
}, { timestamps: true });

// Hash password before saving
userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 12);
  next();
});

// Compare passwords
userSchema.methods.comparePassword = async function (plain) {
  return bcrypt.compare(plain, this.password);
};

userSchema.methods.toJSON = function () {
  const obj = this.toObject();
  delete obj.password;
  return obj;
};

// ── CUSTOMER SCHEMA ──────────────────────────────────────────────
const customerSchema = new mongoose.Schema({
  merchantId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true,
  },
  name: {
    type: String,
    required: [true, 'Customer name is required'],
    trim: true,
    maxlength: 150,
  },
  phone: {
    type: String,
    required: [true, 'Phone number is required'],
    trim: true,
  },
  address: { type: String, trim: true },
  notes:   { type: String, trim: true },
  isActive: { type: Boolean, default: true },
}, { timestamps: true });

// Virtual — total debt balance for this customer
customerSchema.virtual('balance').get(async function () {
  // Computed via aggregation pipeline in routes
  return 0;
});

// ── DEBT SCHEMA ──────────────────────────────────────────────────
const debtSchema = new mongoose.Schema({
  merchantId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true,
  },
  customerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Customer',
    required: [true, 'Customer is required'],
    index: true,
  },
  amount: {
    type: Number,
    required: [true, 'Amount is required'],
    min: [1, 'Amount must be positive'],
  },
  date: {
    type: Date,
    required: [true, 'Date is required'],
    default: Date.now,
  },
  description: {
    type: String,
    required: [true, 'Description is required'],
    trim: true,
    maxlength: 500,
  },
  status: {
    type: String,
    enum: ['unpaid', 'partial', 'paid'],
    default: 'unpaid',
  },
  // Computed field — updated after each payment
  amountPaid: { type: Number, default: 0, min: 0 },
  balance: {
    type: Number,
    default: function () { return this.amount; },
  },
}, { timestamps: true });

// Auto-update balance & status
debtSchema.methods.recalculate = function () {
  this.balance = this.amount - this.amountPaid;
  if (this.balance <= 0) this.status = 'paid';
  else if (this.amountPaid > 0) this.status = 'partial';
  else this.status = 'unpaid';
};

// ── PAYMENT SCHEMA ───────────────────────────────────────────────
const paymentSchema = new mongoose.Schema({
  merchantId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true,
  },
  customerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Customer',
    required: true,
    index: true,
  },
  debtId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Debt',
    required: [true, 'Debt reference is required'],
  },
  amount: {
    type: Number,
    required: [true, 'Payment amount is required'],
    min: [1, 'Payment must be positive'],
  },
  date: {
    type: Date,
    required: true,
    default: Date.now,
  },
  note: { type: String, trim: true, maxlength: 300 },
}, { timestamps: true });

// ── EXPORTS ──────────────────────────────────────────────────────
const User     = mongoose.model('User',     userSchema);
const Customer = mongoose.model('Customer', customerSchema);
const Debt     = mongoose.model('Debt',     debtSchema);
const Payment  = mongoose.model('Payment',  paymentSchema);

module.exports = { User, Customer, Debt, Payment };
