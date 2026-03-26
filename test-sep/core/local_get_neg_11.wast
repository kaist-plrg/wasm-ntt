(assert_invalid
  (module (func $unbound-local (local i32 i64) (local.get 3) drop))
  "unknown local"
)
