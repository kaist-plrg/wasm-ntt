(assert_invalid
  (module (func $large-local (local i32 i64) (local.get 14324343) drop))
  "unknown local"
)
