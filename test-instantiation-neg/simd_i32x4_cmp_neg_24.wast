(assert_invalid
  (module
    (func $i32x4.gt_s-arg-empty (result v128)
      (i32x4.gt_s)
    )
  )
  "type mismatch"
)
