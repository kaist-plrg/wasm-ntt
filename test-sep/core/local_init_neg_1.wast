(assert_invalid
  (module (func $uninit (local $x (ref extern)) (drop (local.get $x))))
  "uninitialized local"
)
