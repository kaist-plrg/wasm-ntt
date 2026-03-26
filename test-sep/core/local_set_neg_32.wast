(assert_invalid
  (module (func $unbound-mixed (param i32) (local i32 i64) (local.set 3 (i32.const 0))))
  "unknown local"
)
