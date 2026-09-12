(assert_invalid
  (module
    (func $i32x4.add-arg-empty (result v128)
      (i32x4.add)
    )
  )
  "type mismatch"
)
