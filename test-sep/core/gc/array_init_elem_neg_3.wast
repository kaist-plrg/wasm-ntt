(assert_invalid
  (module
    (type $a (array (mut funcref)))

    (elem $e1 externref)

    (func (export "array.init_elem-invalid-2") (param $1 (ref $a))
      (array.init_elem $a $e1 (local.get $1) (i32.const 0) (i32.const 0) (i32.const 0))
    )
  )
  "type mismatch"
)
