(assert_invalid
  (module (func $large-param (param i32 i64) (local.tee 714324343 (i32.const 0)) drop))
  "unknown local"
)
