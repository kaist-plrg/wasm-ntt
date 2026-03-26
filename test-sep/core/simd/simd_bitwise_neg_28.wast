(assert_invalid
  (module
    (func $v128.bitselect-arg-empty (result v128)
      (v128.bitselect)
    )
  )
  "type mismatch"
)
