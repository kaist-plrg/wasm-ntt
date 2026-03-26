(assert_invalid
  (module (memory 0)
    (func $v128.store-1st-arg-empty
      (v128.store (v128.const i32x4 0 0 0 0))
    )
  )
  "type mismatch"
)
