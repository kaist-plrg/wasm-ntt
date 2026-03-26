(assert_invalid
  (module
    (func $v128.bitselect-two-args-empty (result v128)
      (v128.bitselect (v128.const i32x4 0 0 0 0))
    )
  )
  "type mismatch"
)
