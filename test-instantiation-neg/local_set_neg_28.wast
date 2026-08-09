(assert_invalid
  (module (func $unbound-local (local i32 i64) (local.set 3 (i32.const 0))))
  "unknown local"
)
