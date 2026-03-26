(assert_invalid
  (module (func $type-break-nested-empty-vs-num (result i32)
    (block (br 1)) (br 0 (i32.const 1))
  ))
  "type mismatch"
)
