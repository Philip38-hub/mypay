import { useState, useEffect } from 'react'
import axios from 'axios'
import './App.css'
import PaymentPage from './pages/PaymentPage'
import SuccessPage from './pages/SuccessPage'

function App() {
  const [currentPage, setCurrentPage] = useState('loading')
  const [sessionData, setSessionData] = useState(null)
  const [paymentData, setPaymentData] = useState(null)
  const [error, setError] = useState(null)

  useEffect(() => {
    const validateQR = async () => {
      try {
        const params = new URLSearchParams(window.location.search)
        const businessId = window.location.pathname.split('/pay/')[1]
        const v = params.get('v')
        const exp = params.get('exp')
        const sig = params.get('sig')

        if (!businessId || !v || !exp || !sig) {
          setError('Invalid QR code')
          setCurrentPage('error')
          return
        }

        const response = await axios.post('http://localhost:4000/api/qr/validate', {
          businessId,
          v: parseInt(v),
          exp: parseInt(exp),
          sig
        })

        setSessionData(response.data)
        setCurrentPage('payment')
      } catch (err) {
        console.error('QR validation error:', err)
        setError(err.response?.data?.error || 'Failed to validate QR')
        setCurrentPage('error')
      }
    }

    validateQR()
  }, [])

  const handlePaymentSuccess = (data) => {
    setPaymentData(data)
    setCurrentPage('success')
  }

  if (currentPage === 'loading') {
    return (
      <div className="container">
        <div className="loading">
          <p>Loading...</p>
        </div>
      </div>
    )
  }

  if (currentPage === 'error') {
    return (
      <div className="container">
        <div className="error-box">
          <h1>Error</h1>
          <p>{error}</p>
        </div>
      </div>
    )
  }

  if (currentPage === 'payment' && sessionData) {
    return (
      <PaymentPage 
        sessionData={sessionData} 
        onSuccess={handlePaymentSuccess}
      />
    )
  }

  if (currentPage === 'success' && paymentData) {
    return <SuccessPage paymentData={paymentData} />
  }

  return null
}

export default App

