(assert_invalid
  (module
    (type $t (func))
    (func $f (param $r funcref)
      (call_ref $t (local.get $r))
    )
  )
  "type mismatch"
)
