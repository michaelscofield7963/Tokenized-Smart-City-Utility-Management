;; Resident Identity Contract
;; Manages consumer profiles for city residents

(define-data-var contract-owner principal tx-sender)

;; Data structure for resident
(define-map residents
  { id: principal }
  {
    name: (string-utf8 100),
    address: (string-utf8 256),
    active: bool,
    registration-date: uint
  }
)

;; Public function to register a new resident
(define-public (register-resident (name (string-utf8 100)) (address (string-utf8 256)))
  (let ((caller tx-sender))
    (if (is-none (map-get? residents {id: caller}))
        (begin
          (map-set residents
            {id: caller}
            {
              name: name,
              address: address,
              active: true,
              registration-date: block-height
            }
          )
          (ok true)
        )
        (err u1) ;; Resident already exists
    )
  )
)

;; Public function to update resident information
(define-public (update-resident-info (name (string-utf8 100)) (address (string-utf8 256)))
  (let ((caller tx-sender))
    (match (map-get? residents {id: caller})
        resident (begin
          (map-set residents
            {id: caller}
            {
              name: name,
              address: address,
              active: (get active resident),
              registration-date: (get registration-date resident)
            }
          )
          (ok true)
        )
        (err u2) ;; Resident not found
    )
  )
)

;; Public function to deactivate a resident
(define-public (deactivate-resident)
  (let ((caller tx-sender))
    (match (map-get? residents {id: caller})
        resident (begin
          (map-set residents
            {id: caller}
            {
              name: (get name resident),
              address: (get address resident),
              active: false,
              registration-date: (get registration-date resident)
            }
          )
          (ok true)
        )
        (err u2) ;; Resident not found
    )
  )
)

;; Read-only function to check if a resident exists and is active
(define-read-only (is-active-resident (id principal))
  (match (map-get? residents {id: id})
    resident (get active resident)
    false
  )
)

;; Read-only function to get resident details
(define-read-only (get-resident-details (id principal))
  (map-get? residents {id: id})
)
