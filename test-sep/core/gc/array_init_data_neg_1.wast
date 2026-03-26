(assert_invalid
  (module
    (type $a (array i8))

    (data $d1 "a")

    (func (export "array.init_data-immutable") (param $1 (ref $a))
      (array.init_data $a $d1 (local.get $1) (i32.const 0) (i32.const 0) (i32.const 0))
    )
  )
  "array is immutable"
)
