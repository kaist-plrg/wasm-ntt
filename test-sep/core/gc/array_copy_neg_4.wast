(assert_invalid
  (module
    (type $a (array (mut i8)))
    (type $b (array (mut (ref $a))))
    (type $c (array (mut (ref $b))))

    (func (export "array.copy-ref-invalid-1") (param $1 (ref $b)) (param $2 (ref $c))
      (array.copy $b $c (local.get $1) (i32.const 0) (local.get $2) (i32.const 0) (i32.const 0))
    )
  )
  "array types do not match"
)
