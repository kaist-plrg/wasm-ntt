(assert_invalid
  (module
    (func $v128.bitselect-1st-arg-empty (result v128)
      (v128.bitselect (v128.const i32x4 0 0 0 0) (v128.const i32x4 0 0 0 0))
    )
  )
  "type mismatch"
)
