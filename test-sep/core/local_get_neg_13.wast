(assert_invalid
  (module (func $unbound-param (param i32 i64) (local.get 2) drop))
  "unknown local"
)
