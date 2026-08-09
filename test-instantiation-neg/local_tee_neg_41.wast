(assert_invalid
  (module (func $unbound-mixed (param i32) (local i32 i64) (local.tee 3 (i32.const 0)) drop))
  "unknown local"
)
