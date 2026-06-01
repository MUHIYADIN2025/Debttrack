# DebtTrack 💰
**Smart Debt Collection Management for Small Businesses**

A full-stack mobile application that allows merchants to record customers who buy on credit, track their debts, and manage payments — with a real-time dashboard and PDF export.

---

## 📁 Project Structure

```
debttrack/
├── backend/                  # Node.js + Express REST API
│   ├── middleware/
│   │   └── auth.js           # JWT authentication middleware
│   ├── models/
│   │   └── index.js          # MongoDB schemas (User, Customer, Debt, Payment)
│   ├── routes/
│   │   ├── auth.js           # Login, register, profile
│   │   ├── customers.js      # Customer CRUD
│   │   ├── debts.js          # Debt management + payment routes
│   │   ├── payments.js       # Payment router export
│   │   ├── dashboard.js      # Stats + reports routes
│   │   └── reports.js        # Reports router export
│   ├── scripts/
│   │   └── seed.js           # Demo data seeder
│   ├── utils/
│   │   └── pdfExport.js      # Server-side PDF generation
│   ├── .env.example          # Environment variable template
│   ├── .gitignore
│   ├── package.json
│   └── server.js             # Express app entry point
│
└── flutter_app/              # Flutter mobile app
    ├── android/
    │   └── app/src/main/
    │       └── AndroidManifest.xml
    ├── lib/
    │   ├── config/
    │   │   └── app_config.dart   # API URL, constants, routes
    │   ├── models/
    │   │   └── models.dart       # Dart data models
    │   ├── screens/
    │   │   └── screens.dart      # All app screens
    │   ├── services/
    │   │   └── api_service.dart  # HTTP client + AuthService
    │   ├── utils/
    │   │   ├── helpers.dart      # Formatters, validators, snackbars
    │   │   └── pdf_generator.dart # Client-side PDF generation
    │   ├── widgets/
    │   │   └── common_widgets.dart # Reusable UI components
    │   └── main.dart             # App entry point + theme
    └── pubspec.yaml              # Flutter dependencies
```

---

## 🚀 Quick Start

### Prerequisites
- Node.js >= 18
- MongoDB (local or Atlas)
- Flutter SDK >= 3.3
- Android Studio / Xcode

---

### 1. Backend Setup

```bash
# Navigate to backend
cd debttrack/backend

# Install dependencies
npm install

# Copy environment file and edit it
cp .env.example .env
nano .env   # Set your MONGODB_URI and JWT_SECRET

# Seed demo data (optional)
node scripts/seed.js

# Start development server
npm run dev

# Start production server
npm start
```

**Demo credentials after seeding:**
| Role     | Email                        | Password   |
|----------|------------------------------|------------|
| Admin    | admin@debttrack.com          | admin123   |
| Merchant | merchant@debttrack.com       | pass123    |

---

### 2. Flutter App Setup

```bash
# Navigate to flutter app
cd debttrack/flutter_app

# Edit the API base URL
# Open lib/config/app_config.dart
# Set baseUrl to your server's IP address:
#   Android emulator: http://10.0.2.2:3000/api
#   Physical device:  http://YOUR_LOCAL_IP:3000/api
#   Production:       https://api.yourdomain.com/api

# Install dependencies
flutter pub get

# Run on emulator or device
flutter run

# Build APK
flutter build apk --release

# Build for iOS
flutter build ipa
```

---

## 🔌 API Reference

### Auth
| Method | Endpoint               | Description          | Auth |
|--------|------------------------|----------------------|------|
| POST   | `/api/auth/register`   | Create account       | ❌   |
| POST   | `/api/auth/login`      | Sign in              | ❌   |
| GET    | `/api/auth/me`         | Get current user     | ✅   |
| PATCH  | `/api/auth/me`         | Update profile       | ✅   |
| POST   | `/api/auth/change-password` | Change password | ✅  |

### Customers
| Method | Endpoint               | Description          | Auth |
|--------|------------------------|----------------------|------|
| GET    | `/api/customers`       | List customers       | ✅   |
| GET    | `/api/customers/:id`   | Get customer details | ✅   |
| POST   | `/api/customers`       | Add customer         | ✅   |
| PATCH  | `/api/customers/:id`   | Update customer      | ✅   |
| DELETE | `/api/customers/:id`   | Delete customer      | ✅   |

### Debts
| Method | Endpoint         | Description        | Auth |
|--------|------------------|--------------------|------|
| GET    | `/api/debts`     | List debts         | ✅   |
| GET    | `/api/debts/:id` | Get debt details   | ✅   |
| POST   | `/api/debts`     | Create debt        | ✅   |
| PATCH  | `/api/debts/:id` | Update debt        | ✅   |
| DELETE | `/api/debts/:id` | Delete debt        | ✅   |

### Payments
| Method | Endpoint             | Description             | Auth |
|--------|----------------------|-------------------------|------|
| GET    | `/api/payments`      | List payments           | ✅   |
| POST   | `/api/payments`      | Record payment          | ✅   |
| DELETE | `/api/payments/:id`  | Reverse payment         | ✅   |

### Dashboard & Reports
| Method | Endpoint                       | Description             | Auth |
|--------|--------------------------------|-------------------------|------|
| GET    | `/api/dashboard`               | Summary stats           | ✅   |
| GET    | `/api/reports/customers`       | Customer debt report    | ✅   |
| GET    | `/api/reports/payments`        | Payment report          | ✅   |
| GET    | `/api/export/customers.pdf`    | Download PDF report     | ✅   |
| GET    | `/api/export/payments.pdf`     | Download PDF report     | ✅   |
| GET    | `/api/health`                  | Server health check     | ❌   |

---

## 🗄️ Database Schema

### Balance Formula
```
Balance = Total Debt Amount − Total Payments Made
```
The system auto-recalculates and updates `balance`, `amountPaid`, and `status` on every payment.

### Collections
```
users       → _id, name, email, password(hashed), role, phone, businessName
customers   → _id, merchantId, name, phone, address, notes, isActive
debts       → _id, merchantId, customerId, amount, amountPaid, balance, date, description, status
payments    → _id, merchantId, customerId, debtId, amount, date, note
```

---

## 🛡️ Security Features
- Passwords hashed with bcryptjs (12 rounds)
- JWT tokens with configurable expiry
- Rate limiting on all endpoints (stricter on login)
- Helmet.js HTTP security headers
- Input validation on all POST/PATCH routes
- Soft deletion for customers (data preserved)
- Merchant isolation: every query filters by `merchantId`

---

## 📱 App Screens

| Screen             | Description                                  |
|--------------------|----------------------------------------------|
| Login              | Email/password authentication                |
| Register           | Create Admin or Merchant account             |
| Dashboard          | Stats overview + collection rate + charts    |
| Customers          | Searchable customer list with balances       |
| Customer Detail    | Debts, payments, and info tabs               |
| Add Customer       | Form with name, phone, address, notes        |
| Debts              | All debts with status filter chips           |
| Add Debt           | Record new debt for a customer               |
| Payments           | All payment history with totals              |
| Record Payment     | Auto-updates debt balance and status         |
| Reports            | Per-customer progress bars + PDF export      |
| Profile            | Account info, settings, logout               |

---

## 🚢 Deployment

### Backend — Railway / Render / VPS

```bash
# Set environment variables:
NODE_ENV=production
MONGODB_URI=mongodb+srv://...   # MongoDB Atlas URI
JWT_SECRET=your_strong_secret
PORT=3000

# Start command:
npm start
```

### MongoDB Atlas (Free Tier)
1. Create account at mongodb.com/cloud/atlas
2. Create a free M0 cluster
3. Add your server IP to Network Access
4. Copy connection string to `MONGODB_URI`

### Flutter — Google Play Store
```bash
# Build release APK
flutter build apk --release

# Build app bundle (preferred for Play Store)
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

---

## 🔧 Configuration

Edit `flutter_app/lib/config/app_config.dart`:
```dart
// Development (Android emulator)
static const String baseUrl = 'http://10.0.2.2:3000/api';

// Production
static const String baseUrl = 'https://api.yourserver.com/api';
```

Edit `backend/.env`:
```env
MONGODB_URI=your_mongodb_connection_string
JWT_SECRET=your_32_char_minimum_secret_key
PORT=3000
```

---

## 📄 License
MIT License — free to use and modify for commercial projects.

---

*Built with ❤️ for Somali small business merchants*

# 👨‍💻 Author
MUHIYADIN2025
