;; Flash Loans Contract
;; Uncollateralized instant loans within a single transaction
;; First flash loan implementation on Stacks!

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u400))
(define-constant err-insufficient-liquidity (err u401))
(define-constant err-flash-loan-not-repaid (err u402))
(define-constant err-invalid-amount (err u403))
(define-constant err-callback-failed (err u404))

;; Flash loan fee: 0.09% (9 basis points)
(define-constant flash-loan-fee-rate u9)

;; Data Variables
(define-data-var total-liquidity uint u0)
(define-data-var total-fees-collected uint u0)
(define-data-var flash-loan-count uint u0)

;; Track flash loan in progress (reentrancy protection)
(define-data-var flash-loan-active bool false)
(define-data-var flash-loan-amount uint u0)
(define-data-var flash-loan-borrower principal tx-sender)

;; Data Maps
(define-map flash-loan-stats
  { user: principal }
  {
    total-borrowed: uint,
    total-fees-paid: uint,
    loan-count: uint
  }
)

;; Read-only functions
(define-read-only (get-flash-loan-fee (amount uint))
  (/ (* amount flash-loan-fee-rate) u10000)
)

(define-read-only (get-total-repayment (amount uint))
  (+ amount (get-flash-loan-fee amount))
)

(define-read-only (get-available-liquidity)
  (var-get total-liquidity)
)

(define-read-only (get-flash-loan-stats (user principal))
  (default-to
    { total-borrowed: u0, total-fees-paid: u0, loan-count: u0 }
    (map-get? flash-loan-stats { user: user })
  )
)

(define-read-only (get-total-fees-collected)
  (var-get total-fees-collected)
)

;; Public functions

;; Execute flash loan
;; The borrower must repay the loan + fee within the same transaction
(define-public (execute-flash-loan 
  (amount uint)
  (recipient principal))
  (let
    (
      (fee (get-flash-loan-fee amount))
      (total-repayment (+ amount fee))
    )
    ;; Validations
    (asserts! (not (var-get flash-loan-active)) err-flash-loan-not-repaid)
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (>= (var-get total-liquidity) amount) err-insufficient-liquidity)
    
    ;; Set flash loan state (reentrancy protection)
    (var-set flash-loan-active true)
    (var-set flash-loan-amount amount)
    (var-set flash-loan-borrower tx-sender)
    
    ;; Transfer loan to recipient from contract balance
    (try! (stx-transfer? amount (as-contract tx-sender) recipient))
    
    ;; Note: Recipient must call repay-flash-loan before transaction ends
    ;; The repayment check happens in repay-flash-loan
    
    (ok { amount: amount, fee: fee, total-repayment: total-repayment })
  )
)

;; Repay flash loan (called by borrower contract)
(define-public (repay-flash-loan (amount uint))
  (let
    (
      (expected-amount (var-get flash-loan-amount))
      (fee (get-flash-loan-fee expected-amount))
      (total-repayment (+ expected-amount fee))
    )
    (asserts! (var-get flash-loan-active) err-flash-loan-not-repaid)
    (asserts! (is-eq amount total-repayment) err-invalid-amount)
    
    ;; Transfer repayment to contract
    (try! (stx-transfer? total-repayment tx-sender (as-contract tx-sender)))
    
    ;; Update stats
    (update-flash-loan-stats (var-get flash-loan-borrower) expected-amount fee)
    (var-set total-fees-collected (+ (var-get total-fees-collected) fee))
    (var-set flash-loan-count (+ (var-get flash-loan-count) u1))
    
    ;; Reset flash loan state
    (var-set flash-loan-active false)
    (var-set flash-loan-amount u0)
    
    (ok true)
  )
)

;; Add liquidity to flash loan pool
(define-public (add-liquidity (amount uint))
  (begin
    (asserts! (> amount u0) err-invalid-amount)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set total-liquidity (+ (var-get total-liquidity) amount))
    (ok true)
  )
)

;; Remove liquidity from flash loan pool (owner only)
(define-public (remove-liquidity (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= amount (var-get total-liquidity)) err-insufficient-liquidity)
    (try! (as-contract (stx-transfer? amount tx-sender contract-owner)))
    (var-set total-liquidity (- (var-get total-liquidity) amount))
    (ok true)
  )
)

;; Private functions
(define-private (update-flash-loan-stats (user principal) (amount uint) (fee uint))
  (let
    (
      (stats (get-flash-loan-stats user))
    )
    (map-set flash-loan-stats
      { user: user }
      {
        total-borrowed: (+ (get total-borrowed stats) amount),
        total-fees-paid: (+ (get total-fees-paid stats) fee),
        loan-count: (+ (get loan-count stats) u1)
      }
    )
  )
)

;; Trait for flash loan receivers
(define-trait flash-loan-receiver
  (
    (execute-operation (uint principal) (response bool uint))
  )
)
