(assert_invalid
  (module (func $large-local (local i32 i64) (local.tee 14324343 (i32.const 0)) drop))
  "unknown local"
)
