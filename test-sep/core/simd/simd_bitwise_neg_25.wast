(assert_invalid
  (module
    (func $v128.andnot-arg-empty (result v128)
      (v128.andnot)
    )
  )
  "type mismatch"
)
