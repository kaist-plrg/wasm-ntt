(assert_invalid
  (module
    (func $i32x4.sub-arg-empty (result v128)
      (i32x4.sub)
    )
  )
  "type mismatch"
)
