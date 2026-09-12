(assert_invalid
  (module (type $t (func)) (table 0 (ref $t)))
  "type mismatch"
)
