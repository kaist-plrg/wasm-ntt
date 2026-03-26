(assert_invalid
  (module
    (table 1 funcref)
    (elem (ref.null func))
  )
  "type mismatch"
)
