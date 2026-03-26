(assert_invalid
  (module (func $type-funcref-implicit (param $r funcref)
    (drop (select (local.get $r) (local.get $r) (i32.const 1)))
  ))
  "type mismatch"
)
