const express = require('express');
const cors = require('cors');
const crypto = require('crypto');
const QRCode = require('qrcode');

const app = express();
const PORT = 4000;
const HMAC_SECRET = 'dev-secret-key-change-in-production';
const QR_EXPIRY_MINUTES = 60;

// In-memory storage
const businesses = new Map();
const sessions = new Map();
const payments = new Map();

// Middleware
app.use(cors());
app.use(express.json());

// ============ UTILITIES ============

function generateId(prefix) {
  return `${prefix}_${crypto.randomBytes(8).toString('hex')}`;
}

function signQR(businessId, qrVersion, expiresAt) {
  const data = `${businessId}:${qrVersion}:${expiresAt}`;
  return crypto.createHmac('sha256', HMAC_SECRET).update(data).digest('hex');
}

function validateQRSignature(businessId, qrVersion, expiresAt, signature) {
  const expectedSig = signQR(businessId, qrVersion, expiresAt);
  return expectedSig === signature;
}

async function generateQRUrl(businessId, qrVersion) {
  const expiresAt = Math.floor(Date.now() / 1000) + (QR_EXPIRY_MINUTES * 60);
  const signature = signQR(businessId, qrVersion, expiresAt);
  
  const qrUrl = `http://localhost:3000/pay/${businessId}?v=${qrVersion}&exp=${expiresAt}&sig=${signature}`;
  const qrImage = await QRCode.toDataURL(qrUrl);
  
  return { qrUrl, qrImage, expiresAt };
}

// ============ ROUTES ============

// Create Business
app.post('/api/business', async (req, res) => {
  try {
    const { displayName, message, paymentType, paymentDetails } = req.body;
    
    if (!displayName) {
      return res.status(400).json({ error: 'displayName required' });
    }

    const businessId = generateId('biz');
    const qrVersion = 1;
    
    const { qrUrl, qrImage, expiresAt } = await generateQRUrl(businessId, qrVersion);
    
    const business = {
      id: businessId,
      displayName,
      message: message || '',
      paymentType: paymentType || 'pochi',
      paymentDetails: paymentDetails || {},
      qrVersion,
      isActive: true,
      createdAt: Date.now()
    };
    
    businesses.set(businessId, business);
    
    res.json({
      id: businessId,
      displayName,
      message,
      paymentType,
      paymentDetails,
      qrUrl,
      qrImage,
      expiresAt
    });
  } catch (error) {
    console.error('Error creating business:', error);
    res.status(500).json({ error: 'Failed to create business' });
  }
});

// Get all businesses
app.get('/api/business', (req, res) => {
  const businessList = Array.from(businesses.values()).map(b => ({
    id: b.id,
    displayName: b.displayName,
    message: b.message,
    paymentType: b.paymentType,
    isActive: b.isActive
  }));
  res.json(businessList);
});

// Validate QR and create session
app.post('/api/qr/validate', (req, res) => {
  try {
    const { businessId, v, exp, sig } = req.body;
    
    if (!businessId || v === undefined || !exp || !sig) {
      return res.status(400).json({ error: 'Missing QR parameters' });
    }

    // Validate signature
    if (!validateQRSignature(businessId, v, exp, sig)) {
      return res.status(401).json({ error: 'Invalid QR signature' });
    }

    // Validate expiry
    if (Math.floor(Date.now() / 1000) > exp) {
      return res.status(401).json({ error: 'QR expired' });
    }

    // Validate business exists and is active
    const business = businesses.get(businessId);
    if (!business || !business.isActive) {
      return res.status(404).json({ error: 'Business not found' });
    }

    // Create session
    const sessionId = generateId('sess');
    const sessionExpiresAt = Date.now() + (5 * 60 * 1000); // 5 minutes
    
    sessions.set(sessionId, {
      id: sessionId,
      businessId,
      expiresAt: sessionExpiresAt,
      createdAt: Date.now()
    });

    res.json({
      sessionId,
      business: {
        id: business.id,
        displayName: business.displayName,
        message: business.message,
        paymentType: business.paymentType
      }
    });
  } catch (error) {
    console.error('Error validating QR:', error);
    res.status(500).json({ error: 'Failed to validate QR' });
  }
});

// Create payment
app.post('/api/payments', async (req, res) => {
  try {
    const { sessionId, amount } = req.body;
    
    if (!sessionId || !amount) {
      return res.status(400).json({ error: 'sessionId and amount required' });
    }

    // Validate session
    const session = sessions.get(sessionId);
    if (!session) {
      return res.status(404).json({ error: 'Session not found' });
    }

    if (Date.now() > session.expiresAt) {
      return res.status(401).json({ error: 'Session expired' });
    }

    // Create payment
    const paymentId = generateId('pay');
    const payment = {
      id: paymentId,
      businessId: session.businessId,
      amount,
      status: 'pending',
      createdAt: Date.now()
    };

    payments.set(paymentId, payment);

    // Simulate 2-second processing delay
    setTimeout(() => {
      payment.status = 'success';
      payment.completedAt = Date.now();
    }, 2000);

    // Return immediately with pending status
    res.json({
      paymentId,
      status: 'pending',
      amount
    });
  } catch (error) {
    console.error('Error creating payment:', error);
    res.status(500).json({ error: 'Failed to create payment' });
  }
});

// Get payment status
app.get('/api/payments/:paymentId', (req, res) => {
  const payment = payments.get(req.params.paymentId);
  if (!payment) {
    return res.status(404).json({ error: 'Payment not found' });
  }
  res.json({
    id: payment.id,
    status: payment.status,
    amount: payment.amount
  });
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.listen(PORT, () => {
  console.log(`Backend running on http://localhost:${PORT}`);
});

