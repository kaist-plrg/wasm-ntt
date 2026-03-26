(assert_invalid
  (module 
    (table 1 funcref)
    (elem (offset (;empty instruction sequence;)))
  )
  "type mismatch"
)
