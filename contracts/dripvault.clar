;; ------------------------------------------------------------
;; Contract: DripVault (Token Faucet)
;; Author: John Kingsley
;; Purpose: Rate-limited faucet for SIP-010 token or STX
;; ------------------------------------------------------------

;; Added SIP-010 trait definition to support token transfers
(define-trait sip-010-trait
  (
    (transfer (uint principal principal (optional (buff 34))) (response bool uint))
    (get-name () (response (string-ascii 32) uint))
    (get-symbol () (response (string-ascii 32) uint))
    (get-decimals () (response uint uint))
    (get-balance (principal) (response uint uint))
    (get-total-supply () (response uint uint))
    (get-token-uri () (response (optional (string-utf8 256)) uint))
  )
)

(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_COOLDOWN_ACTIVE (err u101))
(define-constant ERR_EMPTY_FAUCET (err u102))
(define-constant ERR_PAUSED (err u103))
(define-constant ERR_WRONG_TOKEN (err u104))
(define-constant ERR_WRONG_MODE (err u105))

;; Changed from invalid principal 'STX to optional principal for flexibility
(define-data-var admin principal tx-sender)
(define-data-var faucet-token (optional principal) none) ;; none = STX faucet
(define-data-var reward-amount uint u1000000) ;; 1 STX (microstacks)
(define-data-var cooldown-period uint u86400) ;; 24 hours
(define-data-var paused bool false)

(define-map last-claim {user: principal} {timestamp: uint})

;; ---------------- Admin Functions ----------------

(define-public (set-config (token (optional principal)) (amount uint) (cooldown uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR_NOT_AUTHORIZED)
    (var-set faucet-token token)
    (var-set reward-amount amount)
    (var-set cooldown-period cooldown)
    (ok true)
  )
)

(define-public (toggle-pause)
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR_NOT_AUTHORIZED)
    (var-set paused (not (var-get paused)))
    (ok (var-get paused))
  )
)

;; ---------------- User Claim Functions ----------------

;; Helper to check cooldown logic shared by both claim functions
(define-private (check-cooldown)
  (let
    (
      (last (default-to u0 (get timestamp (map-get? last-claim {user: tx-sender}))))
      (cooldown (var-get cooldown-period))
    )
    (asserts! (>= stacks-block-height (+ last cooldown)) ERR_COOLDOWN_ACTIVE)
    (ok true)
  )
)

;; Split claim into claim-stx and claim-token to handle dynamic dispatch correctly
(define-public (claim-stx)
  (let
    (
      (is-paused (var-get paused))
      (token (var-get faucet-token))
      (reward (var-get reward-amount))
    )
    (begin
      (asserts! (not is-paused) ERR_PAUSED)
      (asserts! (is-none token) ERR_WRONG_MODE) ;; Must be in STX mode
      (try! (check-cooldown))
      
      ;; Fixed stx-transfer? direction: Contract -> User (was User -> Contract)
      (try! (stx-transfer? reward (as-contract tx-sender) tx-sender))
      
      (map-set last-claim {user: tx-sender} {timestamp: stacks-block-height})
      (ok true)
    )
  )
)

(define-public (claim-token (token-trait <sip-010-trait>))
  (let
    (
      (is-paused (var-get paused))
      (token-opt (var-get faucet-token))
      (reward (var-get reward-amount))
    )
    (begin
      (asserts! (not is-paused) ERR_PAUSED)
      (asserts! (is-some token-opt) ERR_WRONG_MODE) ;; Must be in Token mode
      (asserts! (is-eq (contract-of token-trait) (unwrap! token-opt ERR_WRONG_MODE)) ERR_WRONG_TOKEN)
      (try! (check-cooldown))

      ;; Fixed contract-call? syntax by using trait and removing invalid quote on 'transfer
      (let ((res (contract-call? token-trait transfer reward (as-contract tx-sender) tx-sender none)))
        (asserts! (is-ok res) ERR_EMPTY_FAUCET)
        (map-set last-claim {user: tx-sender} {timestamp: stacks-block-height})
        (ok true)
      )
    )
  )
)

;; ---------------- Admin Refill / Withdraw ----------------

(define-public (withdraw-stx (amount uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR_NOT_AUTHORIZED)
    (stx-transfer? amount (as-contract tx-sender) recipient)
  )
)

;; Added withdraw-token to allow admin to withdraw tokens
(define-public (withdraw-token (token-trait <sip-010-trait>) (amount uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR_NOT_AUTHORIZED)
    (contract-call? token-trait transfer amount (as-contract tx-sender) recipient none)
  )
)


(define-read-only (get-admin) (var-get admin))
(define-read-only (get-last-claim (user principal)) 
  (default-to u0 (get timestamp (map-get? last-claim {user: user}))))
(define-read-only (get-config)
  {
    token: (var-get faucet-token),
    reward: (var-get reward-amount),
    cooldown: (var-get cooldown-period),
    paused: (var-get paused)
  }
)
