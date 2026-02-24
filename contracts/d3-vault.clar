;; --------------------------------------------------
;; Contract: d3-vault
;; Description: Distributes deposited STX evenly among registered users
;; --------------------------------------------------

(define-constant ERR_NOT_ADMIN (err u100))
(define-constant ERR_NO_REWARDS (err u102))
(define-constant ERR_NOT_REGISTERED (err u103))

(define-constant admin tx-sender) ;; locked at deploy

(define-data-var recipients (list 100 principal) (list))
(define-data-var recipient-count uint u0)
(define-map rewards-map principal uint) ;; user -> reward
(define-data-var reward-pool uint u0)
(define-map claimed-map principal bool) ;; track claims

;; === Register as a recipient ===
(define-public (register-recipient)
  (ok true)
)

;; === Deposit STX to the reward pool ===
(define-public (deposit-rewards (amount uint))
  (begin
    (asserts! (is-eq tx-sender admin) ERR_NOT_ADMIN)
    (asserts! (> amount u0) ERR_NO_REWARDS)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set reward-pool (+ (var-get reward-pool) amount))
    (ok true)
  )
)
;; === Distribute rewards evenly to all registered users ===
(define-public (distribute-rewards)
  (if (is-eq (var-get recipient-count) u0)
    (err u999)
    (let ((share (/ (var-get reward-pool) (var-get recipient-count))))
      (ok share)
    )
  )
)



;; === Claim your reward ===
(define-public (claim-reward)
  (match (map-get? rewards-map tx-sender)
    some-amount (ok true)
    (err ERR_NOT_REGISTERED)
  )
)

;; === Reset recipient list (admin only) ===
(define-public (reset-cycle)
  (begin
    (asserts! (is-eq tx-sender admin) ERR_NOT_ADMIN)
    (var-set recipients (list))
    (var-set recipient-count u0)
    (ok true)
  )
)

;; === View reward assigned to an address ===
(define-read-only (get-reward (user principal))
  (ok (map-get? rewards-map user))
)

;; === View all recipients ===
(define-read-only (get-recipients)
  (ok (var-get recipients))
)
