(assert_invalid
  (module
    (memory 0)
    (func $type-address-empty-in-local.tee
      (local i32)
      (local.tee 0 (i32.load)) (drop)
    )
  )
  "type mismatch"
)
