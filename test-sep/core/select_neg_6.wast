(assert_invalid
  (module (func $type-externref-implicit (param $r externref)
    (drop (select (local.get $r) (local.get $r) (i32.const 1)))
  ))
  "type mismatch"
)
