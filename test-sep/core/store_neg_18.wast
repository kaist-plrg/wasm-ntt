(assert_invalid
  (module
    (memory 1)
    (func $type-address-empty-in-else
      (i32.const 0) (i32.const 0)
      (if (result i32) (then (i32.const 0)) (else (i32.store)))
    )
  )
  "type mismatch"
)
