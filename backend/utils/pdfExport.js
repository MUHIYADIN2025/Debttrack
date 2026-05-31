// backend/utils/pdfExport.js
// Generates professional PDF reports using pdfkit

const PDFDocument = require('pdfkit');

const COLORS = {
  primary:  '#4F8EF7',
  success:  '#22C55E',
  danger:   '#EF4444',
  warning:  '#F59E0B',
  dark:     '#1E2230',
  gray:     '#6B7280',
  lightGray:'#F3F4F6',
  white:    '#FFFFFF',
};

function fmt(n) {
  return new Intl.NumberFormat('en-US').format(Math.round(n)) + ' SOS';
}

// ── Generate Customer Debt Report PDF ────────────────────────────
function generateCustomerReport(reportData, merchantName) {
  const doc = new PDFDocument({ margin: 50, size: 'A4' });

  // ── Header ───────────────────────────────────────────────────
  doc.rect(0, 0, doc.page.width, 80).fill(COLORS.dark);

  doc.fill(COLORS.white)
     .fontSize(22).font('Helvetica-Bold')
     .text('DebtTrack', 50, 25);

  doc.fontSize(10).font('Helvetica')
     .text('Customer Debt Report', 50, 52);

  doc.text(`Generated: ${new Date().toLocaleDateString('en-GB')}  |  Merchant: ${merchantName}`,
    doc.page.width - 300, 52, { width: 250, align: 'right' });

  doc.moveDown(3);

  // ── Summary Stats ─────────────────────────────────────────────
  const totalDebt      = reportData.reduce((s, r) => s + r.totalDebt, 0);
  const totalPaid      = reportData.reduce((s, r) => s + r.totalPaid, 0);
  const totalRemaining = totalDebt - totalPaid;

  const statY = 100;
  const statW = (doc.page.width - 100) / 3;

  [
    { label: 'Total Debt',      value: fmt(totalDebt),      color: COLORS.danger },
    { label: 'Total Collected', value: fmt(totalPaid),      color: COLORS.success },
    { label: 'Total Remaining', value: fmt(totalRemaining), color: COLORS.warning },
  ].forEach((stat, i) => {
    const x = 50 + i * (statW + 10);
    doc.rect(x, statY, statW, 55).fillAndStroke(COLORS.lightGray, COLORS.lightGray);
    doc.fill(COLORS.gray).fontSize(9).font('Helvetica').text(stat.label.toUpperCase(), x + 10, statY + 10);
    doc.fill(stat.color).fontSize(14).font('Helvetica-Bold').text(stat.value, x + 10, statY + 26, { width: statW - 20 });
  });

  doc.moveDown(5);

  // ── Table Header ──────────────────────────────────────────────
  const tableTop = statY + 75;
  const cols = { name: 50, phone: 185, totalDebt: 290, paid: 375, balance: 455, pct: 520 };

  doc.rect(50, tableTop, doc.page.width - 100, 22).fill(COLORS.dark);
  doc.fill(COLORS.white).fontSize(9).font('Helvetica-Bold');
  doc.text('CUSTOMER',    cols.name,     tableTop + 7);
  doc.text('PHONE',       cols.phone,    tableTop + 7);
  doc.text('TOTAL DEBT',  cols.totalDebt,tableTop + 7);
  doc.text('PAID',        cols.paid,     tableTop + 7);
  doc.text('BALANCE',     cols.balance,  tableTop + 7);
  doc.text('%',           cols.pct,      tableTop + 7);

  // ── Table Rows ────────────────────────────────────────────────
  let y = tableTop + 22;
  reportData.forEach((row, i) => {
    const bg = i % 2 === 0 ? COLORS.white : COLORS.lightGray;
    doc.rect(50, y, doc.page.width - 100, 20).fill(bg);

    doc.fill(COLORS.dark).fontSize(8).font('Helvetica');
    doc.text(row.customer.name,            cols.name,      y + 6, { width: 130, ellipsis: true });
    doc.text(row.customer.phone || '—',    cols.phone,     y + 6);
    doc.text(fmt(row.totalDebt),           cols.totalDebt, y + 6);

    doc.fill(COLORS.success);
    doc.text(fmt(row.totalPaid),           cols.paid,      y + 6);

    doc.fill(row.balance > 0 ? COLORS.danger : COLORS.success);
    doc.text(fmt(row.balance),             cols.balance,   y + 6);

    const pct = row.collectionPct || 0;
    doc.fill(pct > 70 ? COLORS.success : pct > 40 ? COLORS.warning : COLORS.danger);
    doc.text(`${pct}%`,                    cols.pct,       y + 6);

    y += 20;

    // Page break if needed
    if (y > doc.page.height - 80) {
      doc.addPage();
      y = 50;
    }
  });

  // ── Footer ───────────────────────────────────────────────────
  doc.rect(50, doc.page.height - 50, doc.page.width - 100, 1).fill(COLORS.lightGray);
  doc.fill(COLORS.gray).fontSize(8).font('Helvetica')
     .text(`DebtTrack — Confidential Report — Page 1`, 50, doc.page.height - 40, { align: 'center' });

  doc.end();
  return doc;
}

// ── Generate Payment Report PDF ───────────────────────────────────
function generatePaymentReport(payments, merchantName, dateRange) {
  const doc = new PDFDocument({ margin: 50, size: 'A4' });

  // Header
  doc.rect(0, 0, doc.page.width, 80).fill(COLORS.dark);
  doc.fill(COLORS.white).fontSize(22).font('Helvetica-Bold').text('DebtTrack', 50, 25);
  doc.fontSize(10).font('Helvetica').text('Payment Report', 50, 52);

  const rangeStr = dateRange ? `${dateRange.from} – ${dateRange.to}` : 'All time';
  doc.text(`${rangeStr}  |  ${merchantName}`, doc.page.width - 300, 52, { width: 250, align: 'right' });

  doc.moveDown(3);

  const total = payments.reduce((s, p) => s + p.amount, 0);

  // Total collected box
  const boxY = 100;
  doc.rect(50, boxY, doc.page.width - 100, 50).fill(COLORS.success);
  doc.fill(COLORS.white).fontSize(11).font('Helvetica').text('TOTAL COLLECTED', 70, boxY + 10);
  doc.fontSize(18).font('Helvetica-Bold').text(fmt(total), 70, boxY + 24);
  doc.fontSize(11).font('Helvetica').text(`${payments.length} transactions`, doc.page.width - 200, boxY + 24, { width: 130, align: 'right' });

  // Table
  const tableTop = boxY + 70;
  doc.rect(50, tableTop, doc.page.width - 100, 22).fill(COLORS.dark);
  doc.fill(COLORS.white).fontSize(9).font('Helvetica-Bold');
  doc.text('DATE',     60,  tableTop + 7);
  doc.text('CUSTOMER', 130, tableTop + 7);
  doc.text('DEBT',     270, tableTop + 7);
  doc.text('NOTE',     380, tableTop + 7);
  doc.text('AMOUNT',   490, tableTop + 7);

  let y = tableTop + 22;
  payments.forEach((p, i) => {
    const bg = i % 2 === 0 ? COLORS.white : COLORS.lightGray;
    doc.rect(50, y, doc.page.width - 100, 20).fill(bg);
    doc.fill(COLORS.dark).fontSize(8).font('Helvetica');

    const dateStr = new Date(p.date).toLocaleDateString('en-GB');
    doc.text(dateStr,                                               60,  y + 6);
    doc.text(p.customerId?.name || '—',                            130, y + 6, { width: 135, ellipsis: true });
    doc.text(p.debtId?.description || '—',                         270, y + 6, { width: 105, ellipsis: true });
    doc.text(p.note || '—',                                         380, y + 6, { width: 105, ellipsis: true });
    doc.fill(COLORS.success).text(fmt(p.amount),                   490, y + 6);

    y += 20;
    if (y > doc.page.height - 80) { doc.addPage(); y = 50; }
  });

  doc.rect(50, doc.page.height - 50, doc.page.width - 100, 1).fill(COLORS.lightGray);
  doc.fill(COLORS.gray).fontSize(8).font('Helvetica')
     .text('DebtTrack — Confidential Report', 50, doc.page.height - 40, { align: 'center' });

  doc.end();
  return doc;
}

module.exports = { generateCustomerReport, generatePaymentReport };
