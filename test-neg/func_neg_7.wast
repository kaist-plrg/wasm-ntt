(assert_invalid
  (module
    (type $t (func))
    (func $type-local-uninitialized (local $x (ref $t)) (drop (local.get $x)))
  )
  "uninitialized local"
)
