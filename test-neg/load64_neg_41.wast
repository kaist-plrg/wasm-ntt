(assert_invalid
  (module
    (memory i64 0)
    (func $type-address-empty-in-local.set
      (local i32)
      (local.set 0 (i32.load)) (local.get 0) (drop)
    )
  )
  "type mismatch"
)
