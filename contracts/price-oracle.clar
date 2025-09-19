;; price-oracle.clar
;; A Clarity smart contract for serializing and managing price data
;; This contract provides a secure, decentralized mechanism for storing 
;; and retrieving price information with robust access controls.

;; =============================
;; Constants / Error Codes
;; =============================

;; General errors
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-ENTRY-ALREADY-EXISTS (err u101))
(define-constant ERR-ENTRY-NOT-FOUND (err u102))

;; Permission errors
(define-constant ERR-PERMISSION-DENIED (err u200))
(define-constant ERR-ALREADY-REGISTERED (err u201))

;; Role constants
(define-constant ROLE-ADMIN u1)
(define-constant ROLE-ORACLE u2)

;; =============================
;; Data Maps and Variables
;; =============================

;; Contract administrator - initially set to contract deployer
(define-data-var contract-owner principal tx-sender)

;; Price entry registry
(define-map price-entries 
  { symbol: (string-utf8 10) }
  {
    current-price: uint,          ;; Current price in smallest unit
    last-updated: uint,           ;; Block height of last update
    decimals: uint,               ;; Number of decimal places
    source: (string-utf8 50)      ;; Price source/provider
  }
)

;; Oracle registrations
(define-map oracles 
  principal 
  {
    is-active: bool,
    registration-time: uint
  }
)

;; Global price update counter
(define-data-var price-update-counter uint u0)

;; =============================
;; Private Functions
;; =============================

;; Check if the caller is the contract owner
(define-private (is-owner (user principal))
  (is-eq user (var-get contract-owner))
)

;; Check if a principal is a registered oracle
(define-private (is-registered-oracle (user principal))
  (match (map-get? oracles user)
    oracle-data (get is-active oracle-data)
    false
  )
)

;; =============================
;; Read-Only Functions
;; =============================

;; Get current price for a symbol
(define-read-only (get-price (symbol (string-utf8 10)))
  (map-get? price-entries { symbol: symbol })
)

;; Check oracle registration status
(define-read-only (check-oracle-status (oracle principal))
  (map-get? oracles oracle)
)

;; Get total number of price updates
(define-read-only (get-price-update-count)
  (var-get price-update-counter)
)

;; =============================
;; Public Functions
;; =============================

;; Register a new oracle
(define-public (register-oracle)
  (begin
    (asserts! (is-none (map-get? oracles tx-sender)) ERR-ALREADY-REGISTERED)
    (map-set oracles tx-sender {
      is-active: true,
      registration-time: block-height
    })
    (ok true)
  )
)

;; Update price for a symbol
(define-public (update-price 
  (symbol (string-utf8 10)) 
  (new-price uint)
  (decimals uint)
  (source (string-utf8 50))
)
  (begin
    (asserts! (is-registered-oracle tx-sender) ERR-UNAUTHORIZED)
    (map-set price-entries { symbol: symbol } {
      current-price: new-price,
      last-updated: block-height,
      decimals: decimals,
      source: source
    })
    (var-set price-update-counter (+ (var-get price-update-counter) u1))
    (ok true)
  )
)

;; Transfer contract ownership
(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-owner tx-sender) ERR-UNAUTHORIZED)
    (var-set contract-owner new-owner)
    (ok true)
  )
)