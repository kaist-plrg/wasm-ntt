(assert_invalid
  (module
    (type $a (array (mut i8)))
    (type $b (array i16))

    (func (export "array.copy-packed-invalid") (param $1 (ref $a)) (param $2 (ref $b))
      (array.copy $a $b (local.get $1) (i32.const 0) (local.get $2) (i32.const 0) (i32.const 0))
    )
  )
  "array types do not match"
)
