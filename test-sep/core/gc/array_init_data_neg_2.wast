(assert_invalid
  (module
    (type $a (array (mut funcref)))

    (data $d1 "a")

    (func (export "array.init_data-invalid-1") (param $1 (ref $a))
      (array.init_data $a $d1 (local.get $1) (i32.const 0) (i32.const 0) (i32.const 0))
    )
  )
  "array type is not numeric or vector"
)
