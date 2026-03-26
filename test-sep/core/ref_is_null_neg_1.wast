(assert_invalid
  (module (func $ref-vs-num (param i32) (ref.is_null (local.get 0))))
  "type mismatch"
)
