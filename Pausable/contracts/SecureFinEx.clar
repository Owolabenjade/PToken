;; SecureFinEx (SFX) Token Contract
;; A pausable token with recovery system and security features

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u1))
(define-constant ERR_PAUSED (err u2))
(define-constant ERR_NOT_PAUSED (err u3))
(define-constant ERR_BLACKLISTED (err u4))
(define-constant ERR_RATE_LIMIT (err u5))
(define-constant ERR_INVALID_AMOUNT (err u6))
(define-constant RATE_LIMIT_PERIOD u86400) ;; 24 hours in seconds

;; Data Variables
(define-data-var contract-paused bool false)
(define-data-var total-supply uint u1000000000) ;; 1 billion tokens
(define-data-var rate-limit-active bool false)
(define-data-var rate-limit-amount uint u1000)
(define-data-var last-pause-time uint u0)

;; Data Maps
(define-map balances principal uint)
(define-map blacklisted-addresses principal bool)
(define-map admin-signatures principal bool)
(define-map recovery-requests {owner: principal, new-address: principal} bool)
(define-map daily-transfer-amounts {user: principal, day: uint} uint)
(define-map balance-snapshots {user: principal, timestamp: uint} uint)

;; Private Functions
(define-private (is-admin (account principal))
    (or (is-eq account CONTRACT_OWNER)
        (default-to false (get-admin-signature account))))

(define-private (check-rate-limit (sender principal) (amount uint))
    (let ((current-day (/ block-height u144))  ;; ~144 blocks per day
          (current-amount (default-to u0 (get-daily-transfer amount 
            {user: sender, day: current-day}))))
        (if (and rate-limit-active
                (> (+ current-amount amount) rate-limit-amount))
            ERR_RATE_LIMIT
            (ok true))))

(define-private (take-snapshot (address principal))
    (map-set balance-snapshots 
        {user: address, timestamp: block-height}
        (default-to u0 (get-balance address))))

;; Public Functions

;; Token Basic Functions
(define-public (transfer (amount uint) (recipient principal))
    (let ((sender tx-sender)
          (sender-balance (default-to u0 (get-balance sender))))
        (asserts! (not (var-get contract-paused)) ERR_PAUSED)
        (asserts! (not (is-blacklisted sender)) ERR_BLACKLISTED)
        (asserts! (not (is-blacklisted recipient)) ERR_BLACKLISTED)
        (asserts! (>= sender-balance amount) ERR_INVALID_AMOUNT)
        (try! (check-rate-limit sender amount))
        
        (map-set balances sender (- sender-balance amount))
        (map-set balances recipient 
            (+ (default-to u0 (get-balance recipient)) amount))
        (ok true)))

(define-read-only (get-balance (account principal))
    (map-get? balances account))

;; Admin Functions
(define-public (pause-contract)
    (begin
        (asserts! (is-admin tx-sender) ERR_NOT_AUTHORIZED)
        (var-set contract-paused true)
        (var-set last-pause-time block-height)
        (ok true)))

(define-public (unpause-contract)
    (begin
        (asserts! (is-admin tx-sender) ERR_NOT_AUTHORIZED)
        (var-set contract-paused false)
        (var-set rate-limit-active true)  ;; Enable rate limiting after unpause
        (ok true)))

(define-public (add-admin-signature (admin principal))
    (begin
        (asserts! (is-admin tx-sender) ERR_NOT_AUTHORIZED)
        (map-set admin-signatures admin true)
        (ok true)))

(define-public (remove-admin-signature (admin principal))
    (begin
        (asserts! (is-admin tx-sender) ERR_NOT_AUTHORIZED)
        (map-set admin-signatures admin false)
        (ok true)))

;; Blacklist Functions
(define-public (add-to-blacklist (address principal))
    (begin
        (asserts! (is-admin tx-sender) ERR_NOT_AUTHORIZED)
        (map-set blacklisted-addresses address true)
        (take-snapshot address)
        (ok true)))

(define-public (remove-from-blacklist (address principal))
    (begin
        (asserts! (is-admin tx-sender) ERR_NOT_AUTHORIZED)
        (map-set blacklisted-addresses address false)
        (ok true)))

(define-read-only (is-blacklisted (address principal))
    (default-to false (map-get? blacklisted-addresses address)))

;; Recovery System
(define-public (request-recovery (new-address principal))
    (begin
        (asserts! (var-get contract-paused) ERR_NOT_PAUSED)
        (asserts! (not (is-blacklisted tx-sender)) ERR_BLACKLISTED)
        (map-set recovery-requests {owner: tx-sender, new-address: new-address} true)
        (ok true)))

(define-public (approve-recovery (owner principal) (new-address principal))
    (begin
        (asserts! (is-admin tx-sender) ERR_NOT_AUTHORIZED)
        (asserts! (default-to false 
            (map-get? recovery-requests {owner: owner, new-address: new-address}))
            ERR_NOT_AUTHORIZED)
        
        (let ((balance (default-to u0 (get-balance owner))))
            (map-set balances owner u0)
            (map-set balances new-address balance)
            (map-delete recovery-requests {owner: owner, new-address: new-address})
            (ok true))))

;; Rate Limiting
(define-public (set-rate-limit (active bool) (amount uint))
    (begin
        (asserts! (is-admin tx-sender) ERR_NOT_AUTHORIZED)
        (var-set rate-limit-active active)
        (var-set rate-limit-amount amount)
        (ok true)))

;; Snapshot System
(define-read-only (get-snapshot (address principal) (timestamp uint))
    (map-get? balance-snapshots {user: address, timestamp: timestamp}))

;; Initialize contract
(begin
    ;; Set initial balance for contract owner
    (map-set balances CONTRACT_OWNER (var-get total-supply))
    ;; Set contract owner as admin
    (map-set admin-signatures CONTRACT_OWNER true))