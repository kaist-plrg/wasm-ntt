(assert_invalid
  (module
    (func $i32x4.splat-arg-empty (result v128)
      (i32x4.splat)
    )
  )
  "type mismatch"
)
