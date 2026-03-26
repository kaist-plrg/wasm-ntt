(assert_invalid
  (module
    (func $i8x16.gt_s-arg-empty (result v128)
      (i8x16.gt_s)
    )
  )
  "type mismatch"
)
