(assert_invalid
  (module
    (type $s (struct (field i64)))
    (func (export "struct.set-immutable") (param $s (ref $s))
      (struct.set $s 0 (local.get $s) (i64.const 1))
    )
  )
  "field is immutable"
)
