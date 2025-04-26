;; Usage Metering Contract
;; Records consumption of electricity, water, gas

(define-data-var contract-owner principal tx-sender)

;; Data structure for utility usage
(define-map utility-usage
  { resident: principal, utility-type: (string-utf8 20), year: uint, month: uint }
  {
    usage-amount: uint,
    recorded-at: uint
  }
)

;; Define utility types
(define-constant ELECTRICITY "electricity")
(define-constant WATER "water")
(define-constant GAS "gas")

;; Public function to record utility usage
(define-public (record-usage
  (resident principal)
  (utility-type (string-utf8 20))
  (year uint)
  (month uint)
  (usage-amount uint))

  (let ((caller tx-sender))
    ;; Only contract owner can record usage
    (if (is-eq caller (var-get contract-owner))
        (begin
          (map-set utility-usage
            {
              resident: resident,
              utility-type: utility-type,
              year: year,
              month: month
            }
            {
              usage-amount: usage-amount,
              recorded-at: block-height
            }
          )
          (ok true)
        )
        (err u403) ;; Unauthorized
    )
  )
)

;; Read-only function to get usage details
(define-read-only (get-usage-details
  (resident principal)
  (utility-type (string-utf8 20))
  (year uint)
  (month uint))

  (map-get? utility-usage
    {
      resident: resident,
      utility-type: utility-type,
      year: year,
      month: month
    }
  )
)

;; Read-only function to compare usage with previous month
(define-read-only (compare-with-previous-month
  (resident principal)
  (utility-type (string-utf8 20))
  (year uint)
  (month uint))

  (let (
    (current-usage (map-get? utility-usage
      { resident: resident, utility-type: utility-type, year: year, month: month }))
    (prev-month (if (is-eq month u1) u12 (- month u1)))
    (prev-year (if (is-eq month u1) (- year u1) year))
    (prev-usage (map-get? utility-usage
      { resident: resident, utility-type: utility-type, year: prev-year, month: prev-month }))
  )
    (if (and (is-some current-usage) (is-some prev-usage))
        (ok {
          current: (get usage-amount (unwrap-panic current-usage)),
          previous: (get usage-amount (unwrap-panic prev-usage)),
          difference: (- (get usage-amount (unwrap-panic current-usage))
                         (get usage-amount (unwrap-panic prev-usage)))
        })
        (err u404) ;; Data not found
    )
  )
)
