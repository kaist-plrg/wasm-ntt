(assert_invalid
  (module
    (type $f (func))
    (table 0 0 (ref $f))
  )
  "type mismatch"
)
