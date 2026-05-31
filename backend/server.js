// DebtTrack Backend — Node.js + Express + MongoDB
// Run: npm install && node server.js

const express     = require('express');
const mongoose    = require('mongoose');
const cors        = require('cors');
const helmet      = require('helmet');
const morgan      = require('morgan');
const compression = require('compression');
const rateLimit   = require('express-rate-limit');
const dotenv      = require('dotenv');

dotenv.config();

const app = express();

// ── Security & Middleware ─────────────────────────────────────────
app.use(helmet());
app.use(compression());
app.use(cors({
  origin: process.env.CORS_ORIGINS?.split(',') || '*',
  methods: ['GET', 'POST', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(express.json({ limit: '10kb' }));
app.use(express.urlencoded({ extended: true }));
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

// ── Rate Limiting ─────────────────────────────────────────────────
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
  max:      parseInt(process.env.RATE_LIMIT_MAX)        || 100,
  message:  { success: false, message: 'Too many requests, please try again later.' },
});
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, max: 10,
  message: { success: false, message: 'Too many login attempts, please wait 15 minutes.' },
});
app.use('/api/', limiter);
app.use('/api/auth/login', authLimiter);

// ── Database Connection ───────────────────────────────────────────
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/debttrack')
  .then(() => console.log('✅ MongoDB connected'))
  .catch(err => { console.error('❌ MongoDB error:', err); process.exit(1); });

mongoose.connection.on('disconnected', () => console.warn('⚠️  MongoDB disconnected'));

// ── Routes ────────────────────────────────────────────────────────
const { dashRouter, reportsRouter } = require('./routes/dashboard');
const debtsModule = require('./routes/debts');

app.use('/api/auth',      require('./routes/auth'));
app.use('/api/customers', require('./routes/customers'));
app.use('/api/debts',     debtsModule.debtRouter || debtsModule);
app.use('/api/payments',  require('./routes/payments'));
app.use('/api/dashboard', dashRouter);
app.use('/api/reports',   reportsRouter);

// ── PDF Download Endpoints ────────────────────────────────────────
const { generateCustomerReport, generatePaymentReport } = require('./utils/pdfExport');
const { protect } = require('./middleware/auth');
const { Customer, Debt, Payment } = require('./models');

app.get('/api/export/customers.pdf', protect, async (req, res) => {
  try {
    const customers = await Customer.find({ merchantId: req.user._id, isActive: true });
    const report = await Promise.all(customers.map(async (c) => {
      const debts    = await Debt.find({ customerId: c._id });
      const payments = await Payment.find({ customerId: c._id });
      const totalDebt = debts.reduce((s, d) => s + d.amount, 0);
      const totalPaid = payments.reduce((s, p) => s + p.amount, 0);
      return { customer: c.toObject(), totalDebt, totalPaid, balance: totalDebt - totalPaid,
        collectionPct: totalDebt > 0 ? Math.round((totalPaid / totalDebt) * 100) : 0 };
    }));
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', 'attachment; filename="customer-report.pdf"');
    generateCustomerReport(report, req.user.name).pipe(res);
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

app.get('/api/export/payments.pdf', protect, async (req, res) => {
  try {
    const { from, to } = req.query;
    const query = { merchantId: req.user._id };
    if (from || to) { query.date = {}; if (from) query.date.$gte = new Date(from); if (to) query.date.$lte = new Date(to); }
    const payments = await Payment.find(query)
      .populate('customerId', 'name').populate('debtId', 'description').sort({ date: -1 });
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', 'attachment; filename="payment-report.pdf"');
    generatePaymentReport(payments, req.user.name, from && to ? { from, to } : null).pipe(res);
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ── Health Check ──────────────────────────────────────────────────
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', version: '1.0.0', environment: process.env.NODE_ENV,
    database: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected', time: new Date().toISOString() });
});

// ── 404 & Error Handlers ──────────────────────────────────────────
app.use((req, res) => res.status(404).json({ success: false, message: `Route ${req.method} ${req.path} not found` }));
app.use((err, req, res, next) => {
  console.error('❌', err.stack);
  const status = err.status || 500;
  res.status(status).json({ success: false, message: process.env.NODE_ENV === 'production' && status === 500 ? 'Internal server error' : err.message });
});

// ── Start ─────────────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`\n🚀 DebtTrack API → http://localhost:${PORT}\n`);
});

process.on('SIGTERM', async () => { await mongoose.disconnect(); process.exit(0); });
