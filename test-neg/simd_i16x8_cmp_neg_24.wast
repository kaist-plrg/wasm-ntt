(assert_invalid
  (module
    (func $i16x8.gt_s-arg-empty (result v128)
      (i16x8.gt_s)
    )
  )
  "type mismatch"
)
