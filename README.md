# mypay

mypay is a QR-based mobile payment platform designed to simplify everyday payments for small businesses and their customers. It removes the need for customers to manually enter business numbers or account references by enabling a fast scan → enter amount → confirm payment flow using STK push.

Merchants create and manage their businesses through a Flutter mobile app, where they generate a secure QR code to display at their point of sale. Customers scan the QR code with their phone camera, which opens a lightweight web payment page in their browser, allowing them to enter an amount and complete payment with a single confirmation on their phone.

mypay focuses on reducing payment errors, protecting merchant privacy, and delivering a faster, more intuitive payment experience on top of existing mobile money infrastructure.

## 🎯 MVP Features

- ✅ **Merchant Onboarding** – Merchants register and create one or more businesses from a Flutter app
- ✅ **Secure QR Generation** – Businesses generate signed, server-validated QR codes
- ✅ **QR Validation** – Scanned QR links are verified server-side before payments are allowed
- ✅ **Customer Web Checkout** – QR scan opens a React web UI with business details and amount entry
- ✅ **STK Push Flow (Mocked)** – Payment request triggers a simulated STK push confirmation
- ✅ **Session Management** – Short-lived payment sessions (e.g. 5 minutes) to prevent abuse
- ✅ **Payment Confirmation** – Customers receive clear success or failure feedback after payment

## 📁 Project Structure

```
qr-payments-mvp/
├── backend/              # Node.js + Express server
│   ├── index.js         # Main server with all endpoints
│   ├── package.json
│   └── node_modules/
├── merchant_app/        # Flutter mobile app
│   ├── lib/main.dart    # Complete Flutter implementation
│   ├── pubspec.yaml
│   └── ...
├── customer_web/        # React web app
│   ├── src/
│   │   ├── main.jsx
│   │   ├── App.jsx
│   │   ├── App.css
│   │   └── pages/
│   │       ├── PaymentPage.jsx
│   │       └── SuccessPage.jsx
│   ├── index.html
│   ├── vite.config.js
│   ├── package.json
│   └── node_modules/
└── README.md
```

## 🚀 Quick Start

### Prerequisites

- **Node.js** (v14+)
- **Flutter** (latest stable)
- **npm** or **yarn**

### Clone Repository

```bash
git clone https://github.com/Philip38-hub/mypay.git
cd mypay
```

### 1️⃣ Start Backend (Port 4000)

```bash
cd backend
npm install
npm start
```

Expected output:
```
Backend running on http://localhost:4000
```

### 2️⃣ Start React Customer Web App (Port 3000)

```bash
cd customer_web
npm install
npm run dev
```

Expected output:
```
VITE v5.0.8  ready in 123 ms

➜  Local:   http://localhost:3000/
```

### 3️⃣ Start Flutter Merchant App

```bash
cd merchant_app
flutter pub get 
flutter run
```

Select your target (Android emulator, iOS simulator, or web).

---

## 📱 Complete Demo Flow

### Step 1: Create Business (Merchant App)

1. Open Flutter app
2. Tap **Home** tab (default)
3. Tap **➕ Add Business** FAB
4. **Step 1 - Business Details:**
   - Name: `Mary's Mangoes`
   - Message: `Fresh mangoes daily`
   - Tap **Continue**
5. **Step 2 - Payment Type:**
   - Select: `Pochi la Biashara`
   - Tap **Continue**
6. **Step 3 - Payment Details:**
   - Phone: `+254712345678`
   - Tap **Create Business**

### Step 2: View QR Code

- QR code displays with business name and payment type
- QR URL is shown (copyable)
- Tap **Open Customer Page** to test

### Step 3: Customer Payment (Web App)

1. QR opens in browser → `http://localhost:3000/pay/{businessId}?v=1&exp=...&sig=...`
2. Backend validates QR signature and expiry
3. Customer sees:
   - Business name: `Mary's Mangoes`
   - Message: `Fresh mangoes daily`
   - Payment type badge
4. Enter amount: `150`
5. Tap **Pay Now**
6. Loading spinner (2 seconds)
7. Success page shows:
   - ✓ Payment Successful!
   - Business: Mary's Mangoes
   - Amount: KES 150.00
   - Payment ID: `pay_xxx`

### Step 4: Back to Merchant App

- Tap **Back to Businesses**
- Business appears in list
- Tap to view QR again

---

## 🔐 QR Security (Implemented)

### QR URL Format

```
http://localhost:3000/pay/{businessId}
  ?v={qrVersion}
  &exp={timestamp}
  &sig={HMAC-SHA256}
```

### Validation Steps

1. **Signature Validation** - HMAC-SHA256 with secret key
2. **Expiry Check** - QR valid for 60 minutes
3. **Business Verification** - Business must exist and be active
4. **Session Creation** - 5-minute session for payment

### Backend Endpoints

#### Create Business
```
POST /api/business
{
  "displayName": "Mary's Mangoes",
  "message": "Fresh mangoes daily",
  "paymentType": "pochi",
  "paymentDetails": { "phone": "+254712345678" }
}
→ Returns: { id, qrUrl, qrImage, expiresAt }
```

#### Validate QR & Create Session
```
POST /api/qr/validate
{
  "businessId": "biz_xxx",
  "v": 1,
  "exp": 1712345678,
  "sig": "abc123..."
}
→ Returns: { sessionId, business }
```

#### Create Payment
```
POST /api/payments
{
  "sessionId": "sess_xxx",
  "amount": 150
}
→ Returns: { paymentId, status: "pending", amount }
→ After 2s: status becomes "success"
```

#### Get Payment Status
```
GET /api/payments/{paymentId}
→ Returns: { id, status, amount }
```

---

## 📊 In-Memory Data Models

### Business
```js
{
  id: "biz_xxx",
  displayName: "Mary's Mangoes",
  message: "Fresh mangoes daily",
  paymentType: "pochi",
  paymentDetails: { phone: "+254712345678" },
  qrVersion: 1,
  isActive: true,
  createdAt: timestamp
}
```

### QrSession
```js
{
  id: "sess_xxx",
  businessId: "biz_xxx",
  expiresAt: timestamp,
  createdAt: timestamp
}
```

### Payment
```js
{
  id: "pay_xxx",
  businessId: "biz_xxx",
  amount: 150,
  status: "pending" | "success",
  createdAt: timestamp,
  completedAt: timestamp (if success)
}
```

---

## 🎨 UI/UX Features

### Merchant App (Flutter)
- **Bottom Navigation** - Home, Analytics, Profile tabs
- **Business List** - View all created businesses
- **Multi-step Form** - Business details → Payment type → Payment details
- **QR Display** - Shows QR image, URL, and open button
- **Analytics Placeholder** - Future feature
- **Profile Placeholder** - Merchant info

### Customer Web (React)
- **Minimal Design** - Focus on payment flow
- **QR Validation** - Automatic on page load
- **Amount Input** - Simple number field
- **Loading State** - Spinner during payment
- **Success Screen** - Payment confirmation with details

---

## ⚠️ MVP Limitations

- ❌ No real M-Pesa integration
- ❌ No authentication (anyone can create businesses)
- ❌ No persistence (data lost on restart)
- ❌ No error handling (happy path only)
- ❌ No rate limiting
- ❌ No logging
- ❌ QR expires after 60 minutes (hardcoded)
- ❌ Session expires after 5 minutes (hardcoded)

---

## ✅ Success Criteria

If you can complete this flow, the MVP is working:

1. ✅ Create business in Flutter app
2. ✅ Generate QR code
3. ✅ Open QR in browser
4. ✅ See customer payment page
5. ✅ Enter amount and pay
6. ✅ See success confirmation

---

## 🛠️ Troubleshooting

### Backend won't start
```bash
# Check if port 4000 is in use
lsof -i :4000
# Kill process if needed
kill -9 <PID>
```

### React app won't start
```bash
# Clear cache and reinstall
rm -rf node_modules package-lock.json
npm install
npm run dev
```

### Flutter app can't reach backend
- Ensure backend is running on `localhost:4000`
- On Android emulator, use `10.0.2.2:4000` instead of `localhost:4000`
- Check firewall settings

### QR won't open in browser
- Ensure React app is running on `localhost:3000`
- Check browser console for errors
- Verify QR URL format in Flutter app

---

## 📝 Next Steps

1. **Add Database** - PostgreSQL with Prisma ORM
2. **Add Auth** - JWT for merchants, QR for customers
3. **Integrate M-Pesa** - Real STK Push via Safaricom API
4. **Add Logging** - Winston or Pino for debugging
5. **Add Tests** - Jest for backend, Flutter tests
6. **Deploy** - Heroku for backend, Vercel for React
7. **Mobile Optimization** - Responsive design, PWA
8. **Analytics** - Track transactions, revenue per merchant

---

## 📄 License

MIT

---

**Built with ❤️ for the MVP**

