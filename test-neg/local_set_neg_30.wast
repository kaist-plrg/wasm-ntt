(assert_invalid
  (module (func $unbound-param (param i32 i64) (local.set 2 (i32.const 0))))
  "unknown local"
)
