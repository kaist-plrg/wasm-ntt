(assert_invalid
  (module (memory 0)
    (func $v128.store-2nd-arg-empty
      (v128.store (i32.const 0))
    )
  )
  "type mismatch"
)
