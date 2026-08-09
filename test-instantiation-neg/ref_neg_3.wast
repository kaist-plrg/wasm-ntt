(assert_invalid
  (module (global $global-invalid (ref null 1) (ref.null 1)))
  "unknown type"
)
