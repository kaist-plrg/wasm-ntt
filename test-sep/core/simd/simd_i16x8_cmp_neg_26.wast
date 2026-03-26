(assert_invalid
  (module
    (func $i16x8.gt_u-arg-empty (result v128)
      (i16x8.gt_u)
    )
  )
  "type mismatch"
)
