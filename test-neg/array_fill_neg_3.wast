(assert_invalid
  (module
    (type $b (array (mut funcref)))

    (func (export "array.fill-invalid-1") (param $1 (ref $b)) (param $2 i32)
      (array.fill $b (local.get $1) (i32.const 0) (local.get $2) (i32.const 0))
    )
  )
  "type mismatch"
)
