import { useState } from 'react'
import axios from 'axios'

function PaymentPage({ sessionData, onSuccess }) {
  const [amount, setAmount] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  const handleSubmit = async (e) => {
    e.preventDefault()
    
    if (!amount || parseFloat(amount) <= 0) {
      setError('Please enter a valid amount')
      return
    }

    setLoading(true)
    setError(null)

    try {
      const response = await axios.post('http://localhost:4000/api/payments', {
        sessionId: sessionData.sessionId,
        amount: parseFloat(amount)
      })

      // Wait for payment to be processed (2 seconds)
      setTimeout(() => {
        onSuccess({
          paymentId: response.data.paymentId,
          amount: parseFloat(amount),
          business: sessionData.business
        })
      }, 2500)
    } catch (err) {
      console.error('Payment error:', err)
      setError(err.response?.data?.error || 'Payment failed')
      setLoading(false)
    }
  }

  return (
    <div className="container">
      <div className="payment-container">
        <div className="business-info">
          <h1>{sessionData.business.displayName}</h1>
          {sessionData.business.message && (
            <p>{sessionData.business.message}</p>
          )}
          <div className="payment-type">
            {sessionData.business.paymentType}
          </div>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label htmlFor="amount">Amount (KES)</label>
            <input
              id="amount"
              type="number"
              placeholder="Enter amount"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              disabled={loading}
              step="0.01"
              min="0"
            />
          </div>

          {error && (
            <div style={{ color: '#e74c3c', marginBottom: '15px', fontSize: '14px' }}>
              {error}
            </div>
          )}

          <button 
            type="submit" 
            className="button"
            disabled={loading}
          >
            {loading ? (
              <>
                <span className="loading-spinner"></span>
                Processing...
              </>
            ) : (
              'Pay Now'
            )}
          </button>
        </form>
      </div>
    </div>
  )
}

export default PaymentPage

