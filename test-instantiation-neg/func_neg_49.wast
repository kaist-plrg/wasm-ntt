(assert_invalid
  (module (func $type-break-nested-void-vs-num (result i32)
    (block (br 1 (nop))) (br 0 (i32.const 1))
  ))
  "type mismatch"
)
