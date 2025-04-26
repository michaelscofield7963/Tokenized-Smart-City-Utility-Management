;; Payment Processing Contract
;; Handles automated billing for utilities

(define-data-var contract-owner principal tx-sender)

;; Rates for each utility type (in microtokens per unit)
(define-data-var electricity-rate uint u500)
(define-data-var water-rate uint u300)
(define-data-var gas-rate uint u400)

;; Data structure for billing
(define-map bills
  { resident: principal, year: uint, month: uint }
  {
    electricity-amount: uint,
    water-amount: uint,
    gas-amount: uint,
    total-amount: uint,
    paid: bool,
    generated-at: uint,
    paid-at: (optional uint)
  }
)

;; Public function to generate bill
(define-public (generate-bill
  (resident principal)
  (year uint)
  (month uint)
  (electricity-usage uint)
  (water-usage uint)
  (gas-usage uint))

  (let (
    (caller tx-sender)
    (electricity-cost (* electricity-usage (var-get electricity-rate)))
    (water-cost (* water-usage (var-get water-rate)))
    (gas-cost (* gas-usage (var-get gas-rate)))
    (total-cost (+ (+ electricity-cost water-cost) gas-cost))
  )
    ;; Only contract owner can generate bills
    (if (is-eq caller (var-get contract-owner))
        (begin
          (map-set bills
            { resident: resident, year: year, month: month }
            {
              electricity-amount: electricity-cost,
              water-amount: water-cost,
              gas-amount: gas-cost,
              total-amount: total-cost,
              paid: false,
              generated-at: block-height,
              paid-at: none
            }
          )
          (ok total-cost)
        )
        (err u403) ;; Unauthorized
    )
  )
)

;; Public function to pay bill
(define-public (pay-bill (year uint) (month uint))
  (let (
    (caller tx-sender)
    (bill (map-get? bills { resident: caller, year: year, month: month }))
  )
    (match bill
      current-bill
        (if (get paid current-bill)
            (err u100) ;; Already paid
            (begin
              ;; In a real implementation, this would check if payment succeeds
              (map-set bills
                { resident: caller, year: year, month: month }
                (merge current-bill {
                  paid: true,
                  paid-at: (some block-height)
                })
              )
              (ok (get total-amount current-bill))
            ))
      (err u404) ;; Bill not found
    )
  )
)

;; Read-only function to get bill details
(define-read-only (get-bill-details (resident principal) (year uint) (month uint))
  (map-get? bills { resident: resident, year: year, month: month })
)

;; Public functions to update rates (admin only)
(define-public (update-electricity-rate (new-rate uint))
  (let ((caller tx-sender))
    (if (is-eq caller (var-get contract-owner))
        (begin
          (var-set electricity-rate new-rate)
          (ok true)
        )
        (err u403) ;; Unauthorized
    )
  )
)

(define-public (update-water-rate (new-rate uint))
  (let ((caller tx-sender))
    (if (is-eq caller (var-get contract-owner))
        (begin
          (var-set water-rate new-rate)
          (ok true)
        )
        (err u403) ;; Unauthorized
    )
  )
)

(define-public (update-gas-rate (new-rate uint))
  (let ((caller tx-sender))
    (if (is-eq caller (var-get contract-owner))
        (begin
          (var-set gas-rate new-rate)
          (ok true)
        )
        (err u403) ;; Unauthorized
    )
  )
)
