(assert_invalid
  (module
    (func $i8x16.gt_u-arg-empty (result v128)
      (i8x16.gt_u)
    )
  )
  "type mismatch"
)
