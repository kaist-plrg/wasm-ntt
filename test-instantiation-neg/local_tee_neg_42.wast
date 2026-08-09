(assert_invalid
  (module (func $large-mixed (param i64) (local i32 i64) (local.tee 214324343 (i32.const 0)) drop))
  "unknown local"
)
