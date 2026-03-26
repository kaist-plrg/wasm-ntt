(assert_invalid
  (module
    (table 1 funcref)
    (elem (i32.const 0) funcref (item (ref.null func) (ref.null func)))
  )
  "type mismatch"
)
