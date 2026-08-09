(assert_invalid
  (module (func $large-local (local i32 i64) (local.set 14324343 (i32.const 0))))
  "unknown local"
)
