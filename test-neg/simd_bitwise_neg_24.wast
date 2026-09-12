(assert_invalid
  (module
    (func $v128.andnot-1st-arg-empty (result v128)
      (v128.andnot (v128.const i32x4 0 0 0 0))
    )
  )
  "type mismatch"
)
