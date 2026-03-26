(assert_invalid
  (module (table 1 (ref func) (ref.null func)))
  "type mismatch"
)
