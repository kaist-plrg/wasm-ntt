(assert_invalid
  (module
    (type $a (array i8))
    (type $b (array (mut i8)))

    (func (export "array.copy-immutable") (param $1 (ref $a)) (param $2 (ref $b))
      (array.copy $a $b (local.get $1) (i32.const 0) (local.get $2) (i32.const 0) (i32.const 0))
    )
  )
  "array is immutable"
)
