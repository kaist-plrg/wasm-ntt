(assert_invalid
  (module
    (func $type-param-arg-empty-vs-num-in-else (param i32)
      (i32.const 0)
      (if (result i32) (i32.const 0) (then (i32.const 0)) (else (local.set 0)))
    )
  )
  "type mismatch"
)
