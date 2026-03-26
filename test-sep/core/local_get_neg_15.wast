(assert_invalid
  (module (func $unbound-mixed (param i32) (local i32 i64) (local.get 3) drop))
  "unknown local"
)
