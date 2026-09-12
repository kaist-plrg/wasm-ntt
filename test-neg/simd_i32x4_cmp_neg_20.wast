(assert_invalid
  (module
    (func $i32x4.le_s-arg-empty (result v128)
      (i32x4.le_s)
    )
  )
  "type mismatch"
)
