(assert_invalid
  (module (type $t (func))
    (func $type-ref-implicit (param $r (ref $t))
      (drop (select (local.get $r) (local.get $r) (i32.const 1)))
    )
  )
  "type mismatch"
)
