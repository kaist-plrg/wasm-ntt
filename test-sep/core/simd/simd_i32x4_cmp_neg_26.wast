(assert_invalid
  (module
    (func $i32x4.gt_u-arg-empty (result v128)
      (i32x4.gt_u)
    )
  )
  "type mismatch"
)
