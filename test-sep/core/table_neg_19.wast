(assert_invalid
  (module
    (type $f (func))
    (table 10 (ref $f))
  )
  "type mismatch"
)
