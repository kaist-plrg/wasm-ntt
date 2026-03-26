(assert_invalid
  (module
    (global $x (mut i32) (i32.const 0))
    (func $type-param-arg-empty-vs-num-in-global.set (param i32)
      (global.set $x (local.tee 0)) (global.get $x) (drop)
    )
  )
  "type mismatch"
)
