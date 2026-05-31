// backend/scripts/seed.js
// Run: node scripts/seed.js
// Populates the database with demo data for testing

require('dotenv').config({ path: '../.env' });
const mongoose = require('mongoose');
const { User, Customer, Debt, Payment } = require('../models');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/debttrack';

async function seed() {
  console.log('🌱 Connecting to MongoDB...');
  await mongoose.connect(MONGODB_URI);
  console.log('✅ Connected\n');

  // Clear existing data
  await Promise.all([User.deleteMany(), Customer.deleteMany(), Debt.deleteMany(), Payment.deleteMany()]);
  console.log('🗑️  Cleared existing data\n');

  // ── Create Users ──────────────────────────────────────────────
  const admin = await User.create({
    name: 'Ahmed Hassan',
    email: 'admin@debttrack.com',
    password: 'admin123',
    role: 'Admin',
    phone: '+252 61 111 0001',
    businessName: 'Hassan General Store',
  });

  const merchant = await User.create({
    name: 'Fatima Ali',
    email: 'merchant@debttrack.com',
    password: 'pass123',
    role: 'Merchant',
    phone: '+252 61 222 0002',
    businessName: 'Ali Electronics',
  });

  console.log('👤 Created users:', admin.email, merchant.email);

  // ── Create Customers ──────────────────────────────────────────
  const customers = await Customer.insertMany([
    { merchantId: admin._id, name: 'Mohamed Omar',  phone: '+252 61 234 5678', address: 'Hodan District, Mogadishu',    notes: 'Regular customer, pays on time' },
    { merchantId: admin._id, name: 'Amina Warsame', phone: '+252 61 876 5432', address: 'Wadajir District, Mogadishu',  notes: 'Prefers SMS reminders' },
    { merchantId: admin._id, name: 'Hassan Jama',   phone: '+252 61 555 0001', address: 'Karaan District, Mogadishu',   notes: 'Business owner' },
    { merchantId: admin._id, name: 'Safia Aden',    phone: '+252 61 777 2222', address: 'Medina District, Mogadishu',   notes: '' },
    { merchantId: admin._id, name: 'Yusuf Abdi',    phone: '+252 61 999 3333', address: 'Dharkenley, Mogadishu',        notes: 'New customer' },
    { merchantId: merchant._id, name: 'Hodan Farah', phone: '+252 61 444 5555', address: 'Bondhere, Mogadishu',         notes: 'Wholesale buyer' },
  ]);

  console.log(`📋 Created ${customers.length} customers`);

  // ── Create Debts ──────────────────────────────────────────────
  const debts = await Debt.insertMany([
    { merchantId: admin._id, customerId: customers[0]._id, amount: 500000, date: new Date('2026-05-01'), description: 'Electronics purchase',  status: 'partial', amountPaid: 300000, balance: 200000 },
    { merchantId: admin._id, customerId: customers[0]._id, amount: 200000, date: new Date('2026-05-10'), description: 'Mobile phone',           status: 'unpaid',  amountPaid: 0,      balance: 200000 },
    { merchantId: admin._id, customerId: customers[1]._id, amount: 300000, date: new Date('2026-04-15'), description: 'Household goods',         status: 'paid',    amountPaid: 300000, balance: 0 },
    { merchantId: admin._id, customerId: customers[2]._id, amount: 750000, date: new Date('2026-04-20'), description: 'Furniture set',           status: 'partial', amountPaid: 250000, balance: 500000 },
    { merchantId: admin._id, customerId: customers[3]._id, amount: 150000, date: new Date('2026-05-05'), description: 'Groceries',              status: 'unpaid',  amountPaid: 0,      balance: 150000 },
    { merchantId: admin._id, customerId: customers[4]._id, amount: 420000, date: new Date('2026-05-20'), description: 'Building materials',      status: 'unpaid',  amountPaid: 0,      balance: 420000 },
    { merchantId: merchant._id, customerId: customers[5]._id, amount: 900000, date: new Date('2026-05-15'), description: 'Wholesale electronics', status: 'partial', amountPaid: 400000, balance: 500000 },
  ]);

  console.log(`💳 Created ${debts.length} debts`);

  // ── Create Payments ───────────────────────────────────────────
  await Payment.insertMany([
    { merchantId: admin._id,    customerId: customers[0]._id, debtId: debts[0]._id, amount: 300000, date: new Date('2026-05-15'), note: 'Cash payment' },
    { merchantId: admin._id,    customerId: customers[1]._id, debtId: debts[2]._id, amount: 300000, date: new Date('2026-04-28'), note: 'Full payment via EVC Plus' },
    { merchantId: admin._id,    customerId: customers[2]._id, debtId: debts[3]._id, amount: 250000, date: new Date('2026-05-08'), note: 'Partial payment' },
    { merchantId: merchant._id, customerId: customers[5]._id, debtId: debts[6]._id, amount: 400000, date: new Date('2026-05-18'), note: 'Bank transfer' },
  ]);

  console.log('💰 Created payments');
  console.log('\n✅ Seed complete!\n');
  console.log('─────────────────────────────────────');
  console.log('  Admin login:    admin@debttrack.com / admin123');
  console.log('  Merchant login: merchant@debttrack.com / pass123');
  console.log('─────────────────────────────────────\n');

  await mongoose.disconnect();
  process.exit(0);
}

seed().catch((err) => {
  console.error('❌ Seed failed:', err);
  process.exit(1);
});
