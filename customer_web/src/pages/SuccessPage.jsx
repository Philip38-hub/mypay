function SuccessPage({ paymentData }) {
  return (
    <div className="container">
      <div className="success-container">
        <div className="success-icon">✓</div>
        <h1>Payment Successful!</h1>
        <p>Your payment has been processed successfully.</p>
        
        <div className="payment-details">
          <p>
            <strong>Business:</strong> {paymentData.business.displayName}
          </p>
          <p>
            <strong>Amount:</strong> KES {paymentData.amount.toFixed(2)}
          </p>
          <p>
            <strong>Payment ID:</strong> {paymentData.paymentId}
          </p>
          <p>
            <strong>Status:</strong> <span style={{ color: '#27ae60' }}>Success</span>
          </p>
        </div>

        <p style={{ color: '#999', fontSize: '12px', marginTop: '20px' }}>
          Thank you for your payment!
        </p>
      </div>
    </div>
  )
}

export default SuccessPage

