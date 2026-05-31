// backend/routes/reports.js
// Re-exports the reportsRouter defined in dashboard.js

const { reportsRouter } = require('./dashboard');
module.exports = reportsRouter;
