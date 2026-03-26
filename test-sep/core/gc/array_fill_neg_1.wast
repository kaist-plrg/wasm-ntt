(assert_invalid
  (module
    (type $a (array i8))

    (func (export "array.fill-immutable") (param $1 (ref $a)) (param $2 i32)
      (array.fill $a (local.get $1) (i32.const 0) (local.get $2) (i32.const 0))
    )
  )
  "array is immutable"
)
