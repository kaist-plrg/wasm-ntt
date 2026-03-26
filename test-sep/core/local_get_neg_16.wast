(assert_invalid
  (module (func $large-mixed (param i64) (local i32 i64) (local.get 214324343) drop))
  "unknown local"
)
