;; Liquidity Pool Contract
;; Simplified peer-to-peer lending pool with dynamic rates

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u500))
(define-constant err-insufficient-liquidity (err u501))
(define-constant err-insufficient-balance (err u502))
(define-constant err-invalid-amount (err u503))
(define-constant err-pool-paused (err u504))

;; Pool parameters
(define-constant base-rate u500) ;; 5% base APY
(define-constant optimal-utilization u8000) ;; 80%

;; Data Variables
(define-data-var pool-paused bool false)
(define-data-var borrow-nonce uint u0)

;; Data Maps
(define-map liquidity-providers
  { provider: principal }
  {
    deposited: uint,
    available: uint,
    earned: uint
  }
)

(define-map pool-borrows
  { borrower: principal, borrow-id: uint }
  {
    amount: uint,
    lender: principal,
    interest-rate: uint,
    borrow-block: uint,
    repaid: bool
  }
)

;; Read-only functions
(define-read-only (get-lp-info (provider principal))
  (default-to
    { deposited: u0, available: u0, earned: u0 }
    (map-get? liquidity-providers { provider: provider })
  )
)

(define-read-only (get-borrow-info (borrower principal) (borrow-id uint))
  (map-get? pool-borrows { borrower: borrower, borrow-id: borrow-id })
)

;; Calculate simple interest rate (5-15% based on demand)
(define-read-only (get-current-rate)
  (ok base-rate) ;; Simplified: fixed 5% rate
)

;; Public functions

;; Deposit STX to pool
(define-public (deposit-to-pool (amount uint))
  (let
    (
      (lp-info (get-lp-info tx-sender))
    )
    (asserts! (not (var-get pool-paused)) err-pool-paused)
    (asserts! (> amount u0) err-invalid-amount)
    
    ;; Update LP info
    (map-set liquidity-providers
      { provider: tx-sender }
      {
        deposited: (+ (get deposited lp-info) amount),
        available: (+ (get available lp-info) amount),
        earned: (get earned lp-info)
      }
    )
    
    (ok amount)
  )
)

;; Borrow from specific lender
(define-public (borrow-from-pool (amount uint) (lender principal))
  (let
    (
      (borrow-id (var-get borrow-nonce))
      (current-rate (unwrap! (get-current-rate) err-invalid-amount))
      (lender-info (get-lp-info lender))
    )
    (asserts! (not (var-get pool-paused)) err-pool-paused)
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (>= (get available lender-info) amount) err-insufficient-liquidity)
    
    ;; Transfer from lender to borrower
    (try! (stx-transfer? amount lender tx-sender))
    
    ;; Update lender's available balance
    (map-set liquidity-providers
      { provider: lender }
      (merge lender-info { available: (- (get available lender-info) amount) })
    )
    
    ;; Record borrow
    (map-set pool-borrows
      { borrower: tx-sender, borrow-id: borrow-id }
      {
        amount: amount,
        lender: lender,
        interest-rate: current-rate,
        borrow-block: stacks-block-height,
        repaid: false
      }
    )
    
    (var-set borrow-nonce (+ borrow-id u1))
    (ok borrow-id)
  )
)

;; Repay pool borrow
(define-public (repay-pool-borrow (borrow-id uint))
  (let
    (
      (borrow-info (unwrap! (get-borrow-info tx-sender borrow-id) err-invalid-amount))
      (principal-amount (get amount borrow-info))
      (lender (get lender borrow-info))
      (blocks-elapsed (- stacks-block-height (get borrow-block borrow-info)))
      (interest-rate (get interest-rate borrow-info))
      (interest (/ (* (* principal-amount interest-rate) blocks-elapsed) u525600000))
      (total-repayment (+ principal-amount interest))
      (lender-info (get-lp-info lender))
    )
    (asserts! (not (get repaid borrow-info)) err-invalid-amount)
    
    ;; Transfer repayment to lender
    (try! (stx-transfer? total-repayment tx-sender lender))
    
    ;; Update lender's balance
    (map-set liquidity-providers
      { provider: lender }
      {
        deposited: (get deposited lender-info),
        available: (+ (get available lender-info) principal-amount),
        earned: (+ (get earned lender-info) interest)
      }
    )
    
    ;; Mark as repaid
    (map-set pool-borrows
      { borrower: tx-sender, borrow-id: borrow-id }
      (merge borrow-info { repaid: true })
    )
    
    (ok total-repayment)
  )
)

;; Withdraw from pool
(define-public (withdraw-from-pool (amount uint))
  (let
    (
      (lp-info (get-lp-info tx-sender))
    )
    (asserts! (not (var-get pool-paused)) err-pool-paused)
    (asserts! (<= amount (get available lp-info)) err-insufficient-balance)
    
    ;; Update LP info
    (map-set liquidity-providers
      { provider: tx-sender }
      {
        deposited: (- (get deposited lp-info) amount),
        available: (- (get available lp-info) amount),
        earned: (get earned lp-info)
      }
    )
    
    (ok amount)
  )
)

;; Pause pool (owner only)
(define-public (pause-pool)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set pool-paused true)
    (ok true)
  )
)

;; Unpause pool (owner only)
(define-public (unpause-pool)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set pool-paused false)
    (ok true)
  )
)


;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u500))
(define-constant err-insufficient-liquidity (err u501))
(define-constant err-insufficient-balance (err u502))
(define-constant err-invalid-amount (err u503))
(define-constant err-pool-paused (err u504))
(define-constant err-min-lock-period (err u505))

;; Pool parameters
(define-constant optimal-utilization u8000) ;; 80% optimal utilization
(define-constant base-rate u500) ;; 5% base APY
(define-constant slope1 u1000) ;; 10% slope before optimal
(define-constant slope2 u5000) ;; 50% slope after optimal

;; Minimum lock period for deposits (in blocks)
(define-constant min-lock-period u144) ;; ~1 day

;; Data Variables
(define-data-var total-deposits uint u0)
(define-data-var total-borrows uint u0)
(define-data-var total-reserves uint u0)
(define-data-var pool-paused bool false)
(define-data-var lp-token-supply uint u0)

;; Data Maps
(define-map liquidity-providers
  { provider: principal }
  {
    deposited: uint,
    lp-tokens: uint,
    deposit-block: uint,
    rewards-earned: uint
  }
)

(define-map active-borrows
  { borrower: principal, borrow-id: uint }
  {
    amount: uint,
    interest-rate: uint,
    borrow-block: uint,
    repaid: bool
  }
)

(define-data-var borrow-nonce uint u0)

;; Read-only functions

;; Calculate current utilization rate
(define-read-only (get-utilization-rate)
  (let
    (
      (deposits (var-get total-deposits))
      (borrows (var-get total-borrows))
    )
    (if (is-eq deposits u0)
      u0
      (/ (* borrows u10000) deposits)
    )
  )
)

;; Calculate current borrow APY based on utilization
(define-read-only (get-borrow-rate)
  (let
    (
      (utilization (get-utilization-rate))
    )
    (if (<= utilization optimal-utilization)
      ;; Below optimal: base-rate + (utilization * slope1 / optimal)
      (+ base-rate (/ (* utilization slope1) optimal-utilization))
      ;; Above optimal: base-rate + slope1 + ((utilization - optimal) * slope2 / (10000 - optimal))
      (+ (+ base-rate slope1)
         (/ (* (- utilization optimal-utilization) slope2)
            (- u10000 optimal-utilization)))
    )
  )
)

;; Calculate supply APY (what lenders earn)
(define-read-only (get-supply-rate)
  (let
    (
      (utilization (get-utilization-rate))
      (borrow-rate (get-borrow-rate))
    )
    ;; Supply rate = borrow rate * utilization * (1 - reserve factor)
    ;; Reserve factor = 10%
    (/ (* (* borrow-rate utilization) u9000) u100000000)
  )
)

;; Get available liquidity
(define-read-only (get-available-liquidity)
  (- (var-get total-deposits) (var-get total-borrows))
)

;; Get LP info
(define-read-only (get-lp-info (provider principal))
  (default-to
    { deposited: u0, lp-tokens: u0, deposit-block: u0, rewards-earned: u0 }
    (map-get? liquidity-providers { provider: provider })
  )
)

;; Calculate LP token value
(define-read-only (get-lp-token-value)
  (let
    (
      (supply (var-get lp-token-supply))
      (total-value (+ (var-get total-deposits) (var-get total-reserves)))
    )
    (if (is-eq supply u0)
      u1000000 ;; 1:1 ratio initially
      (/ (* total-value u1000000) supply)
    )
  )
)

;; Public functions

;; Deposit STX to earn yield
(define-public (deposit (amount uint))
  (let
    (
      (lp-info (get-lp-info tx-sender))
      (lp-token-value (get-lp-token-value))
      (lp-tokens-to-mint (/ (* amount u1000000) lp-token-value))
    )
    (asserts! (not (var-get pool-paused)) err-pool-paused)
    (asserts! (> amount u0) err-invalid-amount)
    
    ;; Transfer STX to pool
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    ;; Update state
    (var-set total-deposits (+ (var-get total-deposits) amount))
    (var-set lp-token-supply (+ (var-get lp-token-supply) lp-tokens-to-mint))
    
    ;; Update LP info
    (map-set liquidity-providers
      { provider: tx-sender }
      {
        deposited: (+ (get deposited lp-info) amount),
        lp-tokens: (+ (get lp-tokens lp-info) lp-tokens-to-mint),
        deposit-block: stacks-block-height,
        rewards-earned: (get rewards-earned lp-info)
      }
    )
    
    (ok { deposited: amount, lp-tokens: lp-tokens-to-mint })
  )
)

;; Withdraw STX from pool
(define-public (withdraw (lp-tokens uint))
  (let
    (
      (lp-info (get-lp-info tx-sender))
      (lp-token-value (get-lp-token-value))
      (withdrawal-amount (/ (* lp-tokens lp-token-value) u1000000))
      (available (get-available-liquidity))
    )
    (asserts! (not (var-get pool-paused)) err-pool-paused)
    (asserts! (> lp-tokens u0) err-invalid-amount)
    (asserts! (<= lp-tokens (get lp-tokens lp-info)) err-insufficient-balance)
    (asserts! (>= available withdrawal-amount) err-insufficient-liquidity)
    
    ;; Check minimum lock period
    (asserts! (>= (- stacks-block-height (get deposit-block lp-info)) min-lock-period)
              err-min-lock-period)
    
    ;; Transfer STX to user
    (try! (as-contract (stx-transfer? withdrawal-amount tx-sender tx-sender)))
    
    ;; Update state
    (var-set total-deposits (- (var-get total-deposits) withdrawal-amount))
    (var-set lp-token-supply (- (var-get lp-token-supply) lp-tokens))
    
    ;; Update LP info
    (map-set liquidity-providers
      { provider: tx-sender }
      {
        deposited: (- (get deposited lp-info) withdrawal-amount),
        lp-tokens: (- (get lp-tokens lp-info) lp-tokens),
        deposit-block: (get deposit-block lp-info),
        rewards-earned: (get rewards-earned lp-info)
      }
    )
    
    (ok { withdrawn: withdrawal-amount, lp-tokens-burned: lp-tokens })
  )
)

;; Borrow from pool
(define-public (borrow (amount uint))
  (let
    (
      (borrow-id (var-get borrow-nonce))
      (current-rate (get-borrow-rate))
      (available (get-available-liquidity))
    )
    (asserts! (not (var-get pool-paused)) err-pool-paused)
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (>= available amount) err-insufficient-liquidity)
    
    ;; Transfer loan to borrower
    (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
    
    ;; Update state
    (var-set total-borrows (+ (var-get total-borrows) amount))
    (var-set borrow-nonce (+ borrow-id u1))
    
    ;; Record borrow
    (map-set active-borrows
      { borrower: tx-sender, borrow-id: borrow-id }
      {
        amount: amount,
        interest-rate: current-rate,
        borrow-block: stacks-block-height,
        repaid: false
      }
    )
    
    (ok { borrow-id: borrow-id, amount: amount, rate: current-rate })
  )
)

;; Repay borrow
(define-public (repay (borrow-id uint) (amount uint))
  (let
    (
      (borrow-info (unwrap! (map-get? active-borrows 
                              { borrower: tx-sender, borrow-id: borrow-id })
                            err-invalid-amount))
      (principal-amount (get amount borrow-info))
      (blocks-elapsed (- stacks-block-height (get borrow-block borrow-info)))
      (interest-rate (get interest-rate borrow-info))
      ;; Simple interest calculation: principal * rate * time / (blocks per year * 10000)
      (interest (/ (* (* principal-amount interest-rate) blocks-elapsed) u525600000))
      (total-repayment (+ principal-amount interest))
      (reserve-amount (/ interest u10)) ;; 10% to reserves
    )
    (asserts! (not (get repaid borrow-info)) err-invalid-amount)
    (asserts! (>= amount total-repayment) err-insufficient-balance)
    
    ;; Transfer repayment
    (try! (stx-transfer? total-repayment tx-sender (as-contract tx-sender)))
    
    ;; Update state
    (var-set total-borrows (- (var-get total-borrows) principal-amount))
    (var-set total-reserves (+ (var-get total-reserves) reserve-amount))
    
    ;; Mark as repaid
    (map-set active-borrows
      { borrower: tx-sender, borrow-id: borrow-id }
      (merge borrow-info { repaid: true })
    )
    
    (ok { repaid: total-repayment, interest: interest })
  )
)

;; Pause pool (owner only)
(define-public (pause-pool)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set pool-paused true)
    (ok true)
  )
)

;; Unpause pool (owner only)
(define-public (unpause-pool)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set pool-paused false)
    (ok true)
  )
)
