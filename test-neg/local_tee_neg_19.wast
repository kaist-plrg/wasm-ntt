(assert_invalid
  (module
    (func $type-param-arg-empty-vs-num-in-else (param i32)
      (i32.const 0) (i32.const 0)
      (if (result i32) (then (i32.const 0)) (else (local.tee 0))) (drop)
    )
  )
  "type mismatch"
)
