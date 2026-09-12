(assert_invalid
  (module (func $large-param (param i32 i64) (local.get 714324343) drop))
  "unknown local"
)
