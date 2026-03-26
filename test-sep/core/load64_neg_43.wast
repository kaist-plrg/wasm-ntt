(assert_invalid
  (module
    (memory i64 0)
    (global $x (mut i32) (i32.const 0))
    (func $type-address-empty-in-global.set
      (global.set $x (i32.load)) (global.get $x) (drop)
    )
  )
  "type mismatch"
)
