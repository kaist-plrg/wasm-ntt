(assert_invalid
  (module
    (func $i32x4.ne-1st-arg-empty (result v128)
      (i32x4.ne (v128.const i32x4 0 0 0 0))
    )
  )
  "type mismatch"
)
