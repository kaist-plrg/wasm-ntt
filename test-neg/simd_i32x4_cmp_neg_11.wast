(assert_invalid
  (module
    (func $i32x4.eq-1st-arg-empty (result v128)
      (i32x4.eq (v128.const i32x4 0 0 0 0))
    )
  )
  "type mismatch"
)
