(assert_invalid
  (module (type $t (func)) (table 1 (ref $t) (ref.null func)))
  "type mismatch"
)
