(assert_invalid
  (module
    (type $a (array funcref))

    (elem $e1 funcref)

    (func (export "array.init_elem-immutable") (param $1 (ref $a))
      (array.init_elem $a $e1 (local.get $1) (i32.const 0) (i32.const 0) (i32.const 0))
    )
  )
  "array is immutable"
)
