;; SynthFan - Decentralized Creator Economy Platform
;; Implements Fractional Creation Rights (FCR) and Engagement Synthesis Tokens (EST)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-invalid-percentage (err u104))
(define-constant err-insufficient-balance (err u105))
(define-constant err-invalid-price (err u106))

;; Data Variables
(define-data-var platform-fee-percentage uint u250) ;; 2.5% (basis points)

;; Data Maps

;; Creator content registry
(define-map content-registry
    { content-id: uint }
    {
        creator: principal,
        title: (string-ascii 256),
        total-fcr-supply: uint,
        creation-timestamp: uint,
        is-active: bool
    }
)

;; FCR (Fractional Creation Rights) balances
(define-map fcr-balances
    { content-id: uint, holder: principal }
    { balance: uint }
)

;; EST (Engagement Synthesis Tokens) for interaction rights
(define-map est-balances
    { holder: principal }
    { balance: uint }
)

;; Licensing layers for multi-layer protocol
(define-map licensing-layers
    { content-id: uint, layer-id: uint }
    {
        layer-name: (string-ascii 64),
        royalty-percentage: uint, ;; basis points (e.g., 1000 = 10%)
        is-active: bool
    }
)

;; Revenue distribution records
(define-map revenue-distribution
    { content-id: uint, distribution-id: uint }
    {
        total-amount: uint,
        timestamp: uint,
        distributed: bool
    }
)

;; Reputation scores
(define-map reputation-scores
    { user: principal }
    { score: uint }
)

;; Collaborative session tracking
(define-map collaboration-sessions
    { session-id: uint }
    {
        content-id: uint,
        initiator: principal,
        participants: (list 10 principal),
        status: (string-ascii 20),
        timestamp: uint
    }
)

;; Counters
(define-data-var content-id-nonce uint u0)
(define-data-var layer-id-nonce uint u0)
(define-data-var distribution-id-nonce uint u0)
(define-data-var session-id-nonce uint u0)

;; Read-only functions

(define-read-only (get-content-info (content-id uint))
    (map-get? content-registry { content-id: content-id })
)

(define-read-only (get-fcr-balance (content-id uint) (holder principal))
    (default-to 
        { balance: u0 }
        (map-get? fcr-balances { content-id: content-id, holder: holder })
    )
)

(define-read-only (get-est-balance (holder principal))
    (default-to 
        { balance: u0 }
        (map-get? est-balances { holder: holder })
    )
)

(define-read-only (get-licensing-layer (content-id uint) (layer-id uint))
    (map-get? licensing-layers { content-id: content-id, layer-id: layer-id })
)

(define-read-only (get-reputation-score (user principal))
    (default-to 
        { score: u0 }
        (map-get? reputation-scores { user: user })
    )
)

(define-read-only (get-platform-fee)
    (var-get platform-fee-percentage)
)

(define-read-only (get-collaboration-session (session-id uint))
    (map-get? collaboration-sessions { session-id: session-id })
)

;; Private functions

(define-private (calculate-fee (amount uint))
    (/ (* amount (var-get platform-fee-percentage)) u10000)
)

;; Public functions

;; Register new content and mint initial FCR tokens
(define-public (register-content (title (string-ascii 256)) (fcr-supply uint))
    (let
        (
            (new-content-id (+ (var-get content-id-nonce) u1))
            (creator tx-sender)
        )
        (asserts! (> fcr-supply u0) err-invalid-percentage)
        
        ;; Register content
        (map-set content-registry
            { content-id: new-content-id }
            {
                creator: creator,
                title: title,
                total-fcr-supply: fcr-supply,
                creation-timestamp: block-height,
                is-active: true
            }
        )
        
        ;; Mint FCR tokens to creator
        (map-set fcr-balances
            { content-id: new-content-id, holder: creator }
            { balance: fcr-supply }
        )
        
        ;; Update nonce
        (var-set content-id-nonce new-content-id)
        
        ;; Increase reputation
        (unwrap! (increase-reputation creator u10) err-owner-only)
        
        (ok new-content-id)
    )
)

;; Create licensing layer for content
(define-public (create-licensing-layer 
    (content-id uint) 
    (layer-name (string-ascii 64)) 
    (royalty-percentage uint))
    (let
        (
            (content (unwrap! (map-get? content-registry { content-id: content-id }) err-not-found))
            (new-layer-id (+ (var-get layer-id-nonce) u1))
        )
        ;; Only creator can add licensing layers
        (asserts! (is-eq tx-sender (get creator content)) err-unauthorized)
        (asserts! (<= royalty-percentage u10000) err-invalid-percentage)
        
        (map-set licensing-layers
            { content-id: content-id, layer-id: new-layer-id }
            {
                layer-name: layer-name,
                royalty-percentage: royalty-percentage,
                is-active: true
            }
        )
        
        (var-set layer-id-nonce new-layer-id)
        (ok new-layer-id)
    )
)

;; Transfer FCR tokens
(define-public (transfer-fcr (content-id uint) (amount uint) (recipient principal))
    (let
        (
            (sender-balance (get balance (get-fcr-balance content-id tx-sender)))
        )
        (asserts! (>= sender-balance amount) err-insufficient-balance)
        
        ;; Decrease sender balance
        (map-set fcr-balances
            { content-id: content-id, holder: tx-sender }
            { balance: (- sender-balance amount) }
        )
        
        ;; Increase recipient balance
        (let
            (
                (recipient-balance (get balance (get-fcr-balance content-id recipient)))
            )
            (map-set fcr-balances
                { content-id: content-id, holder: recipient }
                { balance: (+ recipient-balance amount) }
            )
        )
        
        (ok true)
    )
)

;; Mint EST tokens for engagement
(define-public (mint-est (recipient principal) (amount uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        
        (let
            (
                (current-balance (get balance (get-est-balance recipient)))
            )
            (map-set est-balances
                { holder: recipient }
                { balance: (+ current-balance amount) }
            )
        )
        
        (ok true)
    )
)

;; Burn EST tokens for specific interactions
(define-public (burn-est (amount uint))
    (let
        (
            (current-balance (get balance (get-est-balance tx-sender)))
        )
        (asserts! (>= current-balance amount) err-insufficient-balance)
        
        (map-set est-balances
            { holder: tx-sender }
            { balance: (- current-balance amount) }
        )
        
        (ok true)
    )
)

;; Distribute revenue to FCR holders
(define-public (distribute-revenue (content-id uint) (total-amount uint))
    (let
        (
            (content (unwrap! (map-get? content-registry { content-id: content-id }) err-not-found))
            (new-distribution-id (+ (var-get distribution-id-nonce) u1))
            (platform-fee (calculate-fee total-amount))
            (distributable-amount (- total-amount platform-fee))
        )
        ;; Only creator can initiate distribution
        (asserts! (is-eq tx-sender (get creator content)) err-unauthorized)
        
        (map-set revenue-distribution
            { content-id: content-id, distribution-id: new-distribution-id }
            {
                total-amount: total-amount,
                timestamp: block-height,
                distributed: true
            }
        )
        
        (var-set distribution-id-nonce new-distribution-id)
        (ok new-distribution-id)
    )
)

;; Start collaborative creation session
(define-public (start-collaboration-session (content-id uint))
    (let
        (
            (content (unwrap! (map-get? content-registry { content-id: content-id }) err-not-found))
            (new-session-id (+ (var-get session-id-nonce) u1))
        )
        (map-set collaboration-sessions
            { session-id: new-session-id }
            {
                content-id: content-id,
                initiator: tx-sender,
                participants: (list tx-sender),
                status: "active",
                timestamp: block-height
            }
        )
        
        (var-set session-id-nonce new-session-id)
        (ok new-session-id)
    )
)

;; Increase reputation score
(define-private (increase-reputation (user principal) (points uint))
    (let
        (
            (current-score (get score (get-reputation-score user)))
        )
        (ok (map-set reputation-scores
            { user: user }
            { score: (+ current-score points) }
        ))
    )
)

;; Update platform fee (owner only)
(define-public (update-platform-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (<= new-fee u1000) err-invalid-percentage) ;; Max 10%
        (var-set platform-fee-percentage new-fee)
        (ok true)
    )
)

;; Deactivate content
(define-public (deactivate-content (content-id uint))
    (let
        (
            (content (unwrap! (map-get? content-registry { content-id: content-id }) err-not-found))
        )
        (asserts! (is-eq tx-sender (get creator content)) err-unauthorized)
        
        (map-set content-registry
            { content-id: content-id }
            (merge content { is-active: false })
        )
        
        (ok true)
    )
)