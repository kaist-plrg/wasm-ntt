(assert_invalid
  (module
    (type $a (array (mut i8)))

    (func (export "array.fill-invalid-1") (param $1 (ref $a)) (param $2 funcref)
      (array.fill $a (local.get $1) (i32.const 0) (local.get $2) (i32.const 0))
    )
  )
  "type mismatch"
)
