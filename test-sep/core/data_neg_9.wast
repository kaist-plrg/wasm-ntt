(assert_invalid
  (module 
    (memory 1)
    (data (offset (;empty instruction sequence;)))
  )
  "type mismatch"
)
