// backend/routes/payments.js
// Re-exports the paymentRouter defined in debts.js

const { paymentRouter } = require('./debts');
module.exports = paymentRouter;
