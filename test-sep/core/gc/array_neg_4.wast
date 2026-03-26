(assert_invalid
  (module
    (type $a (array i64))
    (func (export "array.set-immutable") (param $a (ref $a))
      (array.set $a (local.get $a) (i32.const 0) (i64.const 1))
    )
  )
  "array is immutable"
)
