(assert_invalid
  (module (func $large-mixed (param i64) (local i32 i64) (local.set 214324343 (i32.const 0))))
  "unknown local"
)
