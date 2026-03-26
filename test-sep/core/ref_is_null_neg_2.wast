(assert_invalid
  (module (func $ref-vs-empty (ref.is_null)))
  "type mismatch"
)
