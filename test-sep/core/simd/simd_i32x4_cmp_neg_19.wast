(assert_invalid
  (module
    (func $i32x4.le_s-1st-arg-empty (result v128)
      (i32x4.le_s (v128.const i32x4 0 0 0 0))
    )
  )
  "type mismatch"
)
