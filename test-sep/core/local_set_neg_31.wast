(assert_invalid
  (module (func $large-param (param i32 i64) (local.set 714324343 (i32.const 0))))
  "unknown local"
)
